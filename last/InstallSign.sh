#!/bin/bash

. $KRN_EXE/lib/kernel.sh && LoadModule
. $KRN_EXE/curses/_libcurses.sh

if [ $# -lt 1 ]
then
    echo ""
    echo "Syntax : ${KRN_Help_Prefix}InstallSign Version ..."
    echo ""
    echo "  Version : as it appears in krn List output command"
    echo "            or just the version number"
    echo ""
    exit 1
fi

# Controle des elements de signature
# ----------------------------------
_CursesStep debut IS01 "\033[5;46m Running \033[m"
VerifySigningConditions
case $? in
    1) _CursesStep fin IS01 "\033[31mParameter not defined\033[m"         ; exit 1;;
    2) _CursesStep fin IS01 "\033[31mOne or more missing parameter\033[m" ; exit 1;;
    3) _CursesStep fin IS01 "\033[31mMissing file(s)\033[m"               ; exit 1;;
esac
_CursesStep fin IS01 "\033[22;32mFound\033[m"

VersionList=$*

Debut=$(TopHorloge)

export    TempDir=$KRN_TMP/krn-$$
mkdir -p $TempDir
cd       $TempDir

# Telechargement des paquets
# --------------------------
_CursesStep debut IS02 "\033[5;46m Running \033[m"
GetKernel.sh $VersionList
[ $? -ne 0 ] && exit 1
echo ""
_CursesStep fin IS02 "\033[22;32mDone\033[m"

# Install package
# ---------------
LVBuildList=""
Param=1
for Version in $VersionList
do
    export Step=$(printf "%02d" $Param); ((Param += 1))

    ParseLinuxVersion $Version
    LVBuildList="$LVBuildList $KRN_LVBuild"
    
    # Module procedure & function definition reset
    _OverloadModule $KRN_LVBuild

    # Installation des paquets
    # ------------------------
    _CursesStep debut IS${Step}c "\033[5;46m Running \033[m"
    if [ $(_CheckPackage) = OK ]
    then
	_InstallPackage
	_CursesStep fin IS${Step}c "\033[22;32mDone\033[m"
    else
	_CursesStep fin IS${Step}c "\033[31mFAILED\033[m"
    fi
done

# Signature des noyaux traites
# ----------------------------
Sign.sh $LVBuildList

# Menage de fin de traitement
# ---------------------------
_RemoveTempDirectory $TempDir

ListInstalledKernel
echo   ""
printf "\033[44m InstallSign $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit $?
