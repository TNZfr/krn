
#-------------------------------------------------------------------------------
# Compile
#-------------------------------------------------------------------------------
_VerifyTools ()
{
    ToolsList="bc"
    case $1 in
	COMPIL)
	    ToolsList="$ToolsList debhelper build-essential fakeroot dpkg-dev libssl-dev bc gnupg dirmngr"
	    ToolsList="$ToolsList libelf-dev flex bison libncurses-dev rsync git curl dwarves libdw-dev zstd"
	    ;&
	SIGN)
	    ToolsList="$ToolsList sbsigntool"
	    ;&
	*)
    esac
    
    printh "Verifying tools installation ..."
    [ ! -z "$KRN_INTERNAL" ] && echo "Control list = $ToolsList"
    
    Uninstalled=$(dpkg -l $ToolsList|grep -v -e "^S" -e "^|" -e "^+++" -e "^ii")
    [ "$Uninstalled" != "" ] && $KRN_sudo apt install -y $ToolsList
}

#-------------------------------------------------------------------------------
_SetCurrentConfig ()
{
    printh "Using current config ..."
}

#-------------------------------------------------------------------------------
_MakePkg()
{
    printh "- Make bindeb-pkg ..."
    make bindeb-pkg -j"$(nproc)"           \
	 LOCALVERSION=-"$KRN_ARCHITECTURE" \
	 KDEB_PKGVERSION="$KernelVersion-krn-$(date +%Y%m%d)" > $1 2>&1
}

#-------------------------------------------------------------------------------
_Finalize()
{
    mv $TmpDir/linux-*.deb $CurrentDirectory 2>/dev/null
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
    ls -lh linux-*${KernelVersion}*.deb 2>/dev/null
}

#-------------------------------------------------------------------------------
# Compile Sign
#-------------------------------------------------------------------------------
_MakePkgSign1 ()
{
    printh "- Make all (main compil) ..."
    make all -j"$(nproc)" LOCALVERSION=-"$KRN_ARCHITECTURE" > $1 2>&1
}

#-------------------------------------------------------------------------------
_MakePkgSign2 ()
{
    printh "- Make bindeb-pkg (import sign files and sign kernel) ..."
    make bindeb-pkg -j"$(nproc)"           \
	 LOCALVERSION=-${KRN_ARCHITECTURE} \
	 KDEB_PKGVERSION="$KernelVersion-krn-$(date +%Y%m%d)" > $1 2>&1
}

#-------------------------------------------------------------------------------
# Install
#-------------------------------------------------------------------------------
_CheckPackage()
{
    NbPaquet=$(ls -1 linux-*${KRN_LVPackage}*.deb 2>/dev/null|wc -l)
    [ $NbPaquet -ge 3 ] && echo OK || echo KO
}

#-------------------------------------------------------------------------------
_InstallPackage()
{
    $KRN_sudo dpkg -i --refuse-downgrade linux-*${KRN_LVPackage}*.deb
}

#-------------------------------------------------------------------------------
# Remove
#-------------------------------------------------------------------------------
_RemovePackage ()
{
    PackageList=$(dpkg -l                          \
		       "linux-headers-${Version}*" \
		       "linux-image-*${Version}*"  \
		       "linux-modules-${Version}*" \
		       2>/dev/null | grep ^ii |cut -d' ' -f3)
    
    if [ "$PackageList" != "" ]
    then
	$KRN_sudo apt-get remove --purge $PackageList -y
	return $?
    fi
    return 0
}

#-------------------------------------------------------------------------------
# Sign
#-------------------------------------------------------------------------------
_UpdateGrub ()
{
    $KRN_sudo update-grub
}
