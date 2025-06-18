
#-------------------------------------------------------------------------------
# Compile
#-------------------------------------------------------------------------------
_VerifyTools ()
{
    InstalledPackage=$KRN_TMP/InstalledPackage-$$
    printh "Verifying tools installation ..."
    rpm -qa > $InstalledPackage

    ToolsList="bc"
    case $1 in
	COMPIL)
	    ToolsList="$ToolsList gcc  flex    bison         dwarves        libdw-devel   elfutils-libelf-devel"
	    ToolsList="$ToolsList perl openssl openssl-devel rpm-build      zstd          ncurses-devel"
	    ;&
	SIGN)
	    ToolsList="$ToolsList sbsigntools"
	    ;&
	*)
    esac
    [ ! -z "$KRN_INTERNAL" ] && echo "Control list = $ToolsList"
    
    for Tool in $ToolsList
    do
	grep -q ^$Tool $InstalledPackage
	if [ $? -ne 0 ]
	then
	    $KRN_sudo yum install -y $ToolsList
	    break 
	fi
    done
    rm -f $InstalledPackage
}

#-------------------------------------------------------------------------------
_SetCurrentConfig ()
{
    return 0
}

#-------------------------------------------------------------------------------
_MakePkg()
{
    printh "- Make binrpm-pkg ..."
    make binrpm-pkg -j"$(nproc)" LOCALVERSION=-"$KRN_ARCHITECTURE" > $1 2>&1
}

#-------------------------------------------------------------------------------
_Finalize()
{
    mv -f  $(find rpmbuild/RPMS -name "kernel-*.rpm") $CurrentDirectory 2>/dev/null
}

#-------------------------------------------------------------------------------
_CleanBuildDirectories()
{
    cd $CurrentDirectory
    rm -rf                        \
       $TmpDir                    \
       /dev/shm/Compil-$$         \
       $Archive
}

#-------------------------------------------------------------------------------
_ListAvailable()
{
    ls -lh kernel*-${KernelVersion}_*.rpm 2>/dev/null
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
    printh "- Make binrpm-pkg (import sign files and sign kernel) ..."
    make binrpm-pkg -j"$(nproc)" LOCALVERSION=-"$KRN_ARCHITECTURE" >> $1 2>&1
}

#-------------------------------------------------------------------------------
# Install
#-------------------------------------------------------------------------------
_CheckPackage()
{
    NbPaquet=$(ls -1 kernel-*${KRN_LVPackage}*.rpm 2>/dev/null|wc -l)
    [ $NbPaquet -ge 2 ] && echo OK || echo KO
}

#-------------------------------------------------------------------------------
_InstallPackage()
{
    $KRN_sudo yum install -y kernel-*${KRN_LVPackage}*.rpm
    $KRN_sudo grub2-mkconfig -o /boot/grub2/grub.cfg
}

#-------------------------------------------------------------------------------
# Remove
#-------------------------------------------------------------------------------
_RemovePackage ()
{
    PackageList=$(rpm -qa|grep ^kernel|grep $(echo $Version|cut -d- -f1))
    
    if [ "$PackageList" != "" ]
    then
	$KRN_sudo yum remove -y $PackageList
	Status=$?
	
	$KRN_sudo grub2-mkconfig -o /boot/grub2/grub.cfg
	return $Status
    fi
    return 0
}

#-------------------------------------------------------------------------------
# Sign
#-------------------------------------------------------------------------------
_UpdateGrub ()
{
    $KRN_sudo grub2-mkconfig -o /boot/grub2/grub.cfg
}
