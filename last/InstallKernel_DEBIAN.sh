#!/bin/bash

. $KRN_EXE/_libkernel.sh

if [ $# -lt 1 ]
then
    echo ""
    echo "Syntax : krn Install Version ..."
    echo ""
    echo "  Version : as it appears in krn List output command"
    echo "            or just the version number"
    echo ""
    exit 1
fi

Debut=$(TopHorloge)
VersionList=$*
TempDir=/tmp/krn-$$
mkdir -p $TempDir
cd       $TempDir

# Telechargement des paquets
# --------------------------
GetKernel.sh $VersionList
echo ""

# Installation des paquets
# ------------------------
ListeDEB=""
for Version in $VersionList
do
    [ "$(echo $Version|cut -d. -f3)" = "" ] && Version=${Version}.0
    ListeDEB="$ListeDEB $(ls -1 linux-*${Version}*.deb)"
done
ListeDEB=$(echo $ListeDEB)

[ "$ListeDEB" != "" ] && NbPaquet=$(ls -1 $ListeDEB 2>/dev/null|wc -l) || NbPaquet=0
[ $NbPaquet -ge 3 ]   && $KRN_sudo dpkg -i --refuse-downgrade $ListeDEB
 
# Menage de fin de traitement
# ---------------------------
rm -rf $TempDir

echo   ""
printf "\033[44m InstallKernel $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit $?
