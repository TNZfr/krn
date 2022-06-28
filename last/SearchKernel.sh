#!/bin/bash

. $KRN_EXE/_libkernel.sh

Debut=$(TopHorloge)

# Si pas de critere de recherche, on sort
# ---------------------------------------
if [ $# -eq 0 ]
then
    echo ""
    echo "Syntax : krn Search Version"
    echo ""
    echo "  Version : as it appears in krn List output command"
    echo "            or just the version number"
    echo ""
    exit 1
fi

ListeDistante=/tmp/ListeDistante-$$.txt

Debut=$(TopHorloge)

echo   ""

Version=$1
[ $(echo $Version|cut -c1) = "v" ] && Version=$(echo $Version|cut -c2-)

# 1. Recherche des source kernel.org
# ----------------------------------
Branch="v$(echo $Version|cut -c1).x"
Url=https://cdn.kernel.org/pub/linux/kernel/$Branch/
printf "Kernel.org : Getting available versions ... "
wget -q $Url -O $ListeDistante
echo "done."
echo "----------"

if [ "$(file $ListeDistante |cut -d: -f2|cut -d' ' -f2-4)" = "gzip compressed data," ]
then
    mv $ListeDistante ${ListeDistante}.gz
    gunzip ${ListeDistante}.gz
fi

for VersionFound in $(linux-version sort $(grep tar.xz $ListeDistante|cut -d'"' -f2|rev|cut -d. -f3-|rev|cut -d- -f2|grep $Version))
do
    printf "%-10s \033[mKernel source archive (xz)\033[m\n" $VersionFound
done

# Menage de fin de traitement
rm -f $ListeDistante 

#-------------------------------------------------------------------------------
# La suite ne concerne que les distribs DEBIAN
# --------------------------------------------
if [ $KRN_MODE = DEBIAN ]
then
    # 2. Recherche des paquets Ubuntu/Mainline
    # ----------------------------------------
    Url=https://kernel.ubuntu.com/~kernel-ppa/mainline/
    echo ""
    printf "Ubuntu/Mainline : Getting available versions ... "
    wget -q --no-check-certificate $Url -O $ListeDistante
    echo "done."
    echo "---------------"

    # Affichage de la liste
    for VersionFound in $(linux-version sort $(grep "href=\"v" $ListeDistante|cut -d'>' -f7|cut -d/ -f1|cut -c2-|grep $Version))
    do
	printf "%-10s \033[32mUbuntu package (deb)\033[m\n" $VersionFound
    done
fi

echo   ""
printf "\033[44m Elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit 0
