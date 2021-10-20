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
TempDir=/tmp/krn-$$
mkdir -p $TempDir
cd       $TempDir

# Telechargement des paquets
# --------------------------
GetKernel.sh $*
echo ""

NbPaquet=$(ls -1 *.deb 2>/dev/null|wc -l)

# Installation des paquets
# ------------------------
[ $LOGNAME = root ] && KRN_sudo="" || KRN_sudo="sudo"
[ $NbPaquet -gt 0 ] && $KRN_sudo dpkg -i --refuse-downgrade *.deb
 
# Menage de fin de traitement
# ---------------------------
rm -rf $TempDir

echo   ""
printf "\033[44m InstallKernel elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit $?
