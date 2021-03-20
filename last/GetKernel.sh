#!/bin/bash

. $KRN_EXE/_libkernel.sh

#-------------------------------------------------------------------------------
GetKernelPackage ()
{
    Version=$1
    [ $(echo $Version|cut -c1) = "v" ] && Version=$(echo $Version|cut -c2-)

    InitVariable KRN_WORKSPACE dir "Workspace directory for package building and storage"
    echo ""

    # 1.Recherche dans le repertoire de stockage
    NbFound=$(ls -1 $KRN_WORKSPACE/linux-*$Version*.deb 2>/dev/null|wc -l)
    if [ $NbFound -ge 3 ]
    then
	echo "Version $Version : $NbFound packages available from $KRN_WORKSPACE"
	cp $KRN_WORKSPACE/linux-*$Version*.deb $PWD
	return 0
    fi

    # 2.Recherche sur Ubuntu/Mainline
    GetKernelPackage_UbuntuMainline $Version
    NbFound=$?
    [ $NbFound -ge 4 ] && return 0

    if [ $NbFound -gt 0 ]
    then
	echo "Not enough packages, file(s) removed."
	rm -f linux-*$Version*.deb
    fi

    echo ""
    echo "Linux version $Version not found."
}

#-------------------------------------------------------------------------------
GetKernelPackage_UbuntuMainline ()
{
    Version=$1

    Url=https://kernel.ubuntu.com/~kernel-ppa/mainline/v$Version/
    ListeDistante=/tmp/krn-ListeDistante-${Version}-$$.txt
    ListePaquets=/tmp/krn-ListePaquets-${Version}-$$.txt

    # Recuperation de la liste des paquets
    # ------------------------------------
    echo "Ubuntu/Mainline : Getting file list for $Version ... "
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
	[ $Status -ne 0 ] && \
	    echo "Download error on $Paquet (status $Status)" && \
	    exit 1
    done
    NbDownloaded=$(cat $ListePaquets|wc -l)
    echo "$NbDownloaded Packages downloaded for $Version"

    # Cleaning
    rm -f $ListeDistante $ListePaquets

    return $NbDownloaded
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
    GetKernelPackage $Version 
done

echo   ""
printf "\033[44m GetKernel elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit 0
