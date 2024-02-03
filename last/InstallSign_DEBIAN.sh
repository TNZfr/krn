#!/bin/bash

. $KRN_EXE/_libkernel.sh

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
VerifySigningConditions

Debut=$(TopHorloge)
VersionList=$*
TempDir=$KRN_TMP/krn-$$
mkdir -p $TempDir
cd       $TempDir

# Telechargement des paquets
# --------------------------
GetKernel.sh $VersionList
[ $? -ne 0 ] && exit 1
echo ""

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

[ "$ListeDEB" != "" ] && NbPaquet=$(ls -1 $ListeDEB 2>/dev/null|wc -l) || NbPaquet=0
[ $NbPaquet -ge 3 ]   && $KRN_sudo dpkg -i --refuse-downgrade $ListeDEB

# Signature des noyaux traites
# ----------------------------
SignKernel_${KRN_MODE}.sh $*

# Menage de fin de traitement
# ---------------------------
rm -rf $TempDir

ListInstalledKernel
echo   ""
printf "\033[44m InstallSignKernel $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit $?
