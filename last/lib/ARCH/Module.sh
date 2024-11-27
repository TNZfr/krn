
#-------------------------------------------------------------------------------
# Verify Tools
#-------------------------------------------------------------------------------
_CheckTool ()
{
    printf "Checking $1 ... "
    [ "$(pacman -Qs $1|head -1)" != "" ] && echo "OK" && return

    echo "Not available, installing ..."
    $KRN_sudo pacman -Sy --noconfirm $1
}

#-------------------------------------------------------------------------------
_VerifyTools ()
{
    echo ""
    case $1 in
	COMPIL)
	    _CheckTool gcc
	    _CheckTool make
	    _CheckTool flex
	    _CheckTool zstd
	    _CheckTool cpio
	    _CheckTool dkms
	    _CheckTool bison
	    _CheckTool rsync
	    _CheckTool pahole
	    ;&
	
	SIGN)
	    _CheckTool sbsigntools
	    ;&
	
	*)
	    _CheckTool bc
    esac
    echo ""
}

#-------------------------------------------------------------------------------
# Compile
#-------------------------------------------------------------------------------
_SetCurrentConfig ()
{
    printh "- Current config copy ..."
    zcat /proc/config.gz > .config
    CheckStatus
}

#-------------------------------------------------------------------------------
_MakePkg()
{
    printh "- Make (bzImage and modules) ..."
    make all -j"$(nproc)" LOCALVERSION=-"$KRN_ARCHITECTURE" > $1 2>&1
}

#-------------------------------------------------------------------------------
_Finalize()
{
    # Remove non needed files
    printh "- Remove object files ..."
    find -name "*.o" -exec rm {} \;
    printh "- New size after cleaning = $(echo $(du -hs .)|cut -d' ' -f1)"

    # Build directory packaging
    printh "- Creating ${Directory}.krn.tar.zst ..."
    cd $TmpDir
    tar cf - linux-${KRN_LVArch} | zstd - -o $CurrentDirectory/linux-${KRN_LVArch}.krn.tar.zst
}

#-------------------------------------------------------------------------------
_CleanBuildDirectories()
{
    cd $CurrentDirectory
    rm -rf      \
       $TmpDir  \
       $Archive \
       /dev/shm/Compil-$$
}

#-------------------------------------------------------------------------------
_ListAvailable()
{
    ls -lh linux-*.krn.tar.zst 2>/dev/null
}

#-------------------------------------------------------------------------------
# Compile Sign
#-------------------------------------------------------------------------------
_MakePkgSign1 ()
{
    printh "- Make all (main compil) ..."
    make -j"$(nproc)" all > $1 2>&1
}

#-------------------------------------------------------------------------------
_MakePkgSign2 ()
{
    printh "- Signing modules ..."
    export KBUILD_SIGN_PIN=$KRNSB_PASS
    for ModuleBinary in $(find . -name "*.ko")
    do
	build/scripts/sign-file \
	    sha256              \
	    $KRNSB_PRIV         \
	    $KRNSB_DER          \
	    $ModuleBinary
    done
}

#-------------------------------------------------------------------------------
# Install
#-------------------------------------------------------------------------------
_CheckPackage()
{
    [ -L $KRN_LVBuild ] && echo OK || echo KO
}

#-------------------------------------------------------------------------------
_InstallPackage()
{
    [ ! -d $KRN_LVBuild ] && continue
    cd $KRN_LVBuild

    KernelVersion=$(make kernelversion)

    # Modules install (and signature)
    printh "Linux $KernelVersion modules installation ..."
    chmod 644 certs/signing_key.*
    $KRN_sudo make modules_install -j$(nproc)
    _Status=$?; [ $_Status -ne 0 ] && exit $_Status

    # Copie des fichiers dans /boot
    printh "Deploy vmlinuz-linux-upstream ..."
    $KRN_sudo cp $(make image_name) /boot/vmlinuz-linux-upstream
    _Status=$?; [ $_Status -ne 0 ] && exit $_Status
    
    printh "Build initramfs-linux-upstream.img ..."
    $KRN_sudo mkinitcpio \
	      --kernel   /boot/vmlinuz-linux-upstream \
	      --generate /boot/initramfs-linux-upstream.img
    
    _Status=$?; [ $_Status -ne 0 ] && exit $_Status

    which dkms > /dev/null 2>&1; DKMS_Available=$?
    if [ $DKMS_Available ]
    then
	printh "DKMS modules build for $KernelVersion ..."
	$KRN_sudo dkms autoinstall -k $KernelVersion
	_Status=$?; [ $_Status -ne 0 ] && exit $_Status
    fi

    echo ""
    cd $TempDir
    
    # Mise a jour de GRUB
    # -------------------
    printh "GRUB update ..."
    _UpdateGrub
    _Status=$?; [ $_Status -ne 0 ] && exit $_Status
}

#-------------------------------------------------------------------------------
# Sign
#-------------------------------------------------------------------------------
_UpdateGrub ()
{
    $KRN_sudo grub-mkconfig -o /boot/grub/grub.cfg
}

#-------------------------------------------------------------------------------
# Remove
#-------------------------------------------------------------------------------
_RemovePackage ()
{
    return 0
}

