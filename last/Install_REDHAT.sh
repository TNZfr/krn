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
ListeRPM=""
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
    ListeRPM="$ListeRPM $(ls -1 kernel*-${Version}_*.rpm)"
done
ListeRPM=$(echo $ListeRPM)

[ "$ListeRPM" != "" ] && NbPaquet=$(ls -1 $ListeRPM 2>/dev/null|wc -l) || NbPaquet=0
if [ $NbPaquet -ge 2 ]
then
    $KRN_sudo yum install -y $ListeRPM
    $KRN_sudo grub2-mkconfig -o /boot/grub2/grub.cfg
fi
 
# Menage de fin de traitement
# ---------------------------
rm -rf $TempDir

echo   ""
printf "\033[44m Install $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit $?
