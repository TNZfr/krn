
#-------------------------------------------------------------------------------
_TestAccount()
{
    [ $LOGNAME != root ] && return

    echo ""
    echo "root account is not allowed to run make pacman-pkg command."
    echo "Please use a regular account instead."
    echo ""
    exit 1
}

#-------------------------------------------------------------------------------
# Compile
#-------------------------------------------------------------------------------
_MakePkg()
{
    _TestAccount
    printh "- Make pacman-pkg ..."
    make pacman-pkg -j"$(nproc)" LOCALVERSION=-"$KRN_ARCHITECTURE" > $1 2>&1
}

#-------------------------------------------------------------------------------
_Finalize()
{
    FileList=$(ls -1 linux-upstream-*.pkg.tar.zst|grep -v "linux-upstream-api-headers")
    [ "$FileList" != "" ] && mv -f $FileList $CurrentDirectory 2>/dev/null
}

#-------------------------------------------------------------------------------
_ListAvailable()
{
    ls -lh linux-upstream-*.pkg.tar.zst 2>/dev/null
}

#-------------------------------------------------------------------------------
# Compile Sign
#-------------------------------------------------------------------------------
_MakePkgSign1 ()
{
    _TestAccount
    printh "- Make all (main compil) ..."
    make all -j"$(nproc)" LOCALVERSION=-"$KRN_ARCHITECTURE" > $1 2>&1
}

#-------------------------------------------------------------------------------
_MakePkgSign2 ()
{
    printh "- Make pacman-pkg (import sign files and sign kernel) ..."
    make pacman-pkg -j"$(nproc)" LOCALVERSION=-"$KRN_ARCHITECTURE" > $1 2>&1
}


#-------------------------------------------------------------------------------
# Install
#-------------------------------------------------------------------------------
_CheckPackage()
{
    NbPaquet=$(ls -1 linux-upstream-*${KRN_LVPackage}*.pkg.tar.zst 2>/dev/null|wc -l)
    [ $NbPaquet -ge 2 ] && echo OK || echo KO
}

#-------------------------------------------------------------------------------
_InstallPackage()
{
    # Arch package install
    $KRN_sudo pacman -U --noconfirm linux-upstream-*${KRN_LVPackage}*.pkg.tar.zst
    
    printh "GRUB update ..."
    $KRN_sudo grub-mkconfig -o /boot/grub/grub.cfg
    CheckStatus
}
