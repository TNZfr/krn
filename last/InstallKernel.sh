#!/bin/bash
 
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
[ $NbPaquet -gt 0 ] && sudo dpkg -i *.deb
 
# Menage de fin de traitement
# ---------------------------
rm -rf $TempDir
 
exit $?
