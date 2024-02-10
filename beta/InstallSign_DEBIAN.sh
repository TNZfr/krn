#!/bin/bash

. $KRN_EXE/_libkernel.sh
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

#----------------------------------------
_CursesVar KRNC_PID=$$
#----------------------------------------

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

Debut=$(TopHorloge)
VersionList=$*
TempDir=$KRN_TMP/krn-$$
mkdir -p $TempDir
cd       $TempDir

# Telechargement des paquets
# --------------------------
_CursesStep debut IS02 "\033[5;46m Running \033[m"
GetKernel.sh $VersionList
[ $? -ne 0 ] && exit 1
echo ""
_CursesStep fin IS02 "\033[22;32mDone\033[m"

# Installation des paquets
# ------------------------
ListeDEB=""
for Version in $VersionList
do
    if [ ${Version:0:3} = "ckc" ]
    then
	if [ "$(echo $Version|grep rc)" = "" ]
	then
	    Version=$(echo $Version|cut -d'-' -f2)
	else
	    Version=$(echo $Version|cut -d'-' -f2,3)
	fi
    fi

    [ "$(echo $Version|cut -d. -f3)" = "" ] && Version=${Version}.0
    ListeDEB="$ListeDEB $(ls -1 linux-*${Version}*.deb)"
done
ListeDEB=$(echo $ListeDEB)

_CursesStep debut IS03 "\033[5;46m Running \033[m"
[ "$ListeDEB" != "" ] && NbPaquet=$(ls -1 $ListeDEB 2>/dev/null|wc -l) || NbPaquet=0
if [ $NbPaquet -ge 3 ]
then
    $KRN_sudo dpkg -i --refuse-downgrade $ListeDEB
    _CursesStep fin IS03 "\033[22;32mDone\033[m"
else
    _CursesStep fin IS03 "\033[31mFAILED $NbPaquet / 3\033[m"
fi

# Signature des noyaux traites
# ----------------------------
Sign_${KRN_MODE}.sh $*

# Menage de fin de traitement
# ---------------------------
rm -rf $TempDir

ListInstalledKernel
echo   ""
printf "\033[44m InstallSign $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit $?
