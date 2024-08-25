#!/bin/bash

. $KRN_EXE/lib/kernel.sh && LoadModule
. $KRN_EXE/curses/_libcurses.sh

if [ $# -lt 1 ]
then
    echo ""
    echo "Syntax : ${KRN_Help_Prefix}Install Version ..."
    echo ""
    echo "  Version : as it appears in krn List output command"
    echo "            or just the version number"
    echo ""
    exit 1
fi

Debut=$(TopHorloge)
VersionList=$*
TempDir=$KRN_TMP/krn-$$
mkdir -p $TempDir
cd       $TempDir

# Telechargement des paquets
# --------------------------
_CursesStep debut INS01 "\033[5;46m Running \033[m"
GetKernel.sh $VersionList
if [ $? -ne 0 ]
then
    _CursesStep fin INS01 "\033[31mFAILED\033[m"
    exit 1
fi
echo ""
_CursesStep fin INS01 "\033[22;32mDone\033[m"

# Install package
# ---------------
Param=1
for Version in $VersionList
do
    export Step=$(printf "%02d" $Param); ((Param += 1))

    ParseLinuxVersion $Version
    
    # Module procedure & function definition reset
    _OverloadModule $KRN_LVBuild

    # Installation des paquets
    # ------------------------
    _CursesStep debut INS${Step}b "\033[5;46m Running \033[m"
    if [ $(_CheckPackage) = OK ]
    then
	_InstallPackage
	_CursesStep fin INS${Step}b "\033[22;32mDone\033[m"
    else
	_CursesStep fin INS${Step}b "\033[31mFAILED\033[m"
    fi
done

# Cleaning
# --------
_RemoveTempDirectory $TempDir

ListInstalledKernel
echo   ""
printf "\033[44m Install $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit $?
