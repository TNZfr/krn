#!/bin/bash

. $KRN_EXE/_libkernel.sh

Url=https://kernel.ubuntu.com/~kernel-ppa/mainline/
ListeDistante=/tmp/ListeDistante-$$.txt
 
# Recuperation de la liste des versions
# -------------------------------------
Debut=$(TopHorloge)
printf "Getting available versions ... "
wget -q $Url -O $ListeDistante
echo "done."

# Affichage de la liste
# ---------------------
if [ $# -gt 0 ]
then
    grep "href=\"v" $ListeDistante|cut -d'>' -f7|cut -d/ -f1 | grep -e $(echo $*|sed 's/ / -e /g')
else
    grep "href=\"v" $ListeDistante|cut -d'>' -f7|cut -d/ -f1
fi

# Menage de fin de traitement
# ---------------------------
rm -f $ListeDistante
Status=$?

echo ""
echo "Installed kernel(s)"
echo "-------------------"
ls -1 /lib/modules
echo ""
echo "Duree : $(AfficheDuree $Debut $(TopHorloge))"
echo ""

exit $Status
