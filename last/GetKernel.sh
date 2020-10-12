#!/bin/bash

. $KRN_EXE/_libkernel.sh

#-------------------------------------------------------------------------------
GetKernelPackage ()
{
    Version=$1
    [ $(echo $Version|cut -c1) != "v" ] && Version=v$Version

    Url=https://kernel.ubuntu.com/~kernel-ppa/mainline/$Version/
    ListeDistante=/tmp/krn-ListeDistante-${Version}-$$.txt
    ListePaquets=/tmp/krn-ListePaquets-${Version}-$$.txt

    # Recuperation de la liste des paquets
    # ------------------------------------
    echo "Getting file list for $Version ... "
    wget -q $Url -O $ListeDistante

    grep linux-headers        $ListeDistante|grep all          |cut -d= -f2 |cut -d\" -f2|grep .deb|uniq >> $ListePaquets
    grep linux-headers        $ListeDistante|grep $Architecture|cut -d= -f2 |cut -d\" -f2|grep .deb      >> $ListePaquets
    grep linux-image-unsigned $ListeDistante|grep $Architecture|cut -d= -f2 |cut -d\" -f2|grep .deb      >> $ListePaquets
    grep linux-modules        $ListeDistante|grep $Architecture|cut -d= -f2 |cut -d\" -f2|grep .deb      >> $ListePaquets
    
    # Exclusion des lowlatency
    # ------------------------
    grep -v lowlatency $ListePaquets      > ${ListePaquets}.tmp
    mv   -f           ${ListePaquets}.tmp    $ListePaquets

    # Suppression des doublons
    # ------------------------
    sort $ListePaquets|uniq > ${ListePaquets}.tmp
    mv -f                     ${ListePaquets}.tmp $ListePaquets

    # Recuperation des paquets (exclusion des lowlatency)
    # ------------------------
    for Paquet in $(cat $ListePaquets)
    do
	echo "Downloading $Paquet ... "
	wget -q $Url/$Paquet -O $(basename $Paquet)
	Status=$?
	[ $Status -ne 0 ] && echo "Download error on $Paquet (status $Status)" && exit 1
    done
    echo "$(cat $ListePaquets|wc -l) Packages downloaded for $Version"

    # Cleaning
    rm -f $ListeDistante $ListePaquets
}

#-------------------------------------------------------------------------------
# Main

if [ $# -lt 1 ]
then
    echo ""
    echo "Syntax : krn Get Version ..."
    echo ""
    echo "  Version : as it appears in krn List output command"
    echo "            or just the version number"
    echo ""
    exit 1
fi

Debut=$(TopHorloge)
Architecture=amd64

for Version in $*
do
    GetKernelPackage $Version &
done
wait

echo ""
echo "Duree de telechargement : $(AfficheDuree $Debut $(TopHorloge))"
echo ""

exit 0
