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

ListeDistante=$KRN_TMP/ListeDistante-$$.txt
ListeVersion=$KRN_TMP/ListeVersion-$$.txt

Debut=$(TopHorloge)

echo   ""

Version=$1
[ $(echo $Version|cut -c1) = "v" ] && Version=$(echo $Version|cut -c2-)

# 1. Recherche des sources git.kernel.org
# ---------------------------------------
Url=https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/refs/
printf "\033[34mgit.kernel.org\033[m : Getting available versions ... "
wget -q $Url -O $ListeDistante
echo "done."
printf "\033[34m--------------\033[m\n"

if [ "$(file $ListeDistante |cut -d: -f2|cut -d' ' -f2-4)" = "gzip compressed data," ]
then
    mv $ListeDistante ${ListeDistante}.gz
    gunzip ${ListeDistante}.gz
fi

# Récupération de la liste des versions présentes
grep tar.gz $ListeDistante|tr ['<>'] ['\n\n']|grep ^linux|grep rc|cut -d'-' -f2,3|cut -d. -f1,2|grep $Version > $ListeVersion

if [ $(cat $ListeVersion|wc -l) -gt 0 ]
then
    for VersionFound in $(cat $ListeVersion|linux-version sort)
    do
	printf "%-10s \033[mKernel source archive (gz)\033[m\n" $VersionFound
    done
else
    echo "No kernel sources available."
fi
echo ""

# 2. Recherche des sources cdn.kernel.org
# ---------------------------------------
Branch="v$(echo $Version|cut -c1).x"
Url=https://cdn.kernel.org/pub/linux/kernel/$Branch/
printf "\033[34mcdn.kernel.org\033[m : Getting available versions ... "
wget -q $Url -O $ListeDistante
echo "done."
printf "\033[34m--------------\033[m\n"

if [ "$(file $ListeDistante |cut -d: -f2|cut -d' ' -f2-4)" = "gzip compressed data," ]
then
    mv $ListeDistante ${ListeDistante}.gz
    gunzip ${ListeDistante}.gz
fi

# Récupération de la liste des versions présentes
grep tar.xz $ListeDistante|grep linux-$Version|cut -d'"' -f2|rev|cut -d. -f3-|rev|cut -d- -f2|linux-version sort > $ListeVersion

if [ $(cat $ListeVersion|wc -l) -gt 0 ]
then
    for VersionFound in $(cat $ListeVersion)
    do
	printf "%-10s \033[mKernel source archive (xz)\033[m\n" $VersionFound
    done
else
    echo "No kernel sources available."
fi

#-------------------------------------------------------------------------------
# La suite ne concerne que les distribs DEBIAN
# --------------------------------------------
if [ $KRN_MODE = DEBIAN ]
then
    # 3. Recherche des paquets Ubuntu/Mainline
    # ----------------------------------------
    Url=https://kernel.ubuntu.com/~kernel-ppa/mainline/
    echo ""
    printf "\033[34mUbuntu/Mainline\033[m : Getting available versions ... "
    wget -q --no-check-certificate $Url -O $ListeDistante
    echo "done."
    printf "\033[34m---------------\033[m\n"

    # Affichage de la liste
    for VersionFound in $(grep "href=\"v" $ListeDistante|grep v$Version|cut -d'>' -f7|cut -d/ -f1|cut -c2-|linux-version sort)
    do
	printf "%-10s \033[32mUbuntu package (deb)\033[m\n" $VersionFound
    done
fi

# Menage de fin de traitement
rm -f $ListeDistante $ListeVersion

echo   ""
printf "\033[44m Elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit 0
