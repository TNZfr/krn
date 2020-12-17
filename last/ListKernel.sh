#!/bin/bash

. $KRN_EXE/_libkernel.sh

ListeDistante=/tmp/ListeDistante-$$.txt
InitVariable KRN_WORKSPACE dir "Workspace directory for package building and storage"

Debut=$(TopHorloge)

Version=$1
[ $(echo $Version|cut -c1) = "v" ] && Version=$(echo $Version|cut -c2-)

# 1. Recherche des source kernel.org
# ----------------------------------
Branch=v5.x
[ $# -gt 0 ] && Branch="v$(echo $Version|cut -c1).x"
Url=https://cdn.kernel.org/pub/linux/kernel/$Branch/
echo ""
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
    grep tar.xz $ListeDistante | cut -d'"' -f2|rev|cut -d. -f3-|rev|cut -d- -f2 | grep -e $(echo $*|sed 's/ / -e /g') 
else
    grep tar.xz $ListeDistante | cut -d'"' -f2|rev|cut -d. -f3-|rev|cut -d- -f2
fi

# 2. Recherche des paquets Ubuntu/Mainline
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
    grep "href=\"v" $ListeDistante|cut -d'>' -f7|cut -d/ -f1|cut -c2- | grep -e $(echo $*|sed 's/ / -e /g')
else
    grep "href=\"v" $ListeDistante|cut -d'>' -f7|cut -d/ -f1|cut -c2-
fi

# Menage de fin de traitement
rm -f $ListeDistante
Status=$?

# 3. Liste des paquets compiles en local
# --------------------------------------
echo ""
echo "Local workspace : $KRN_WORKSPACE"
echo "---------------"
cd $KRN_WORKSPACE
ls -1 linux-image*.deb|cut -d_ -f2

# 4. Liste des noyaux installes
# -----------------------------
echo ""
echo "Installed kernel(s)"
echo "-------------------"
ls -1 /lib/modules
echo ""
echo "Elapsed : $(AfficheDuree $Debut $(TopHorloge))"
echo ""

exit $Status
