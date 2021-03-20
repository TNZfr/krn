#!/bin/bash

. $KRN_EXE/_libkernel.sh

ListeDistante=/tmp/ListeDistante-$$.txt
InitVariable KRN_WORKSPACE dir "Workspace directory for package building and storage"

Debut=$(TopHorloge)

echo   ""
printf "Current kernel : \033[34m$(uname -r)\033[m\n"

# 1. Liste des noyaux installes
# -----------------------------
echo ""
echo "Installed kernel(s)"
echo "-------------------"
SortVersion $(ls -1 /lib/modules)

# 2. Liste des paquets compiles en local
# --------------------------------------
echo ""
echo "Local workspace : $KRN_WORKSPACE"
echo "---------------"
cd $KRN_WORKSPACE
SortVersion $(ls -1 linux-image*.deb 2>/dev/null|cut -d_ -f2)
echo ""

# Si pas de critere de recherche, on sort
# ---------------------------------------
[ $# -eq 0 ] && exit 0

Version=$1
[ $(echo $Version|cut -c1) = "v" ] && Version=$(echo $Version|cut -c2-)

# 3. Recherche des source kernel.org
# ----------------------------------
Branch=v5.x
[ $# -gt 0 ] && Branch="v$(echo $Version|cut -c1).x"
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

if [ $# -gt 0 ]
then
    SortVersion $(grep tar.xz $ListeDistante|cut -d'"' -f2|rev|cut -d. -f3-|rev|cut -d- -f2|grep $Version)
else
    SortVersion $(grep tar.xz $ListeDistante|cut -d'"' -f2|rev|cut -d. -f3-|rev|cut -d- -f2)
fi

# 4. Recherche des paquets Ubuntu/Mainline
# ----------------------------------------
Url=https://kernel.ubuntu.com/~kernel-ppa/mainline/
echo ""
printf "Ubuntu/Mainline : Getting available versions ... "
wget -q $Url -O $ListeDistante
echo "done."
echo "---------------"

# Affichage de la liste
if [ $# -gt 0 ]
then
    SortVersion $(grep "href=\"v" $ListeDistante|cut -d'>' -f7|cut -d/ -f1|cut -c2-|grep $Version)
else
    SortVersion $(grep "href=\"v" $ListeDistante|cut -d'>' -f7|cut -d/ -f1|cut -c2-)
fi

echo   ""
printf "\033[44m Elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

# Menage de fin de traitement
rm -f $ListeDistante
Status=$?

exit $Status
