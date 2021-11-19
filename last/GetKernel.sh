#!/bin/bash

. $KRN_EXE/_libkernel.sh

#-------------------------------------------------------------------------------
GetKernelPackage ()
{
    Version=$1
    [ $(echo $Version|cut -c1) = "v" ] && Version=$(echo $Version|cut -c2-)
    echo ""

    # 1.Recherche dans le repertoire de stockage (deb)
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
    wget -q --no-check-certificate $Url -O $ListeDistante

    grep linux-headers        $ListeDistante|grep all              |cut -d= -f2 |cut -d\" -f2|grep .deb|uniq >> $ListePaquets
    grep linux-headers        $ListeDistante|grep $KRN_ARCHITECTURE|cut -d= -f2 |cut -d\" -f2|grep .deb      >> $ListePaquets
    grep linux-image-unsigned $ListeDistante|grep $KRN_ARCHITECTURE|cut -d= -f2 |cut -d\" -f2|grep .deb      >> $ListePaquets
    grep linux-modules        $ListeDistante|grep $KRN_ARCHITECTURE|cut -d= -f2 |cut -d\" -f2|grep .deb      >> $ListePaquets
    
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
	wget -q --no-check-certificate $Url/$Paquet -O $(basename $Paquet)
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

ListeVersion=$*
for Version in $ListeVersion
do
    case $(echo $KRN_MODE|cut -d- -f1) in
	ARCH)
	    if [ -L $Version ]
	    then
		echo "* link already exists for ${KRN_MODE}-linux-$Version"
		continue
	    fi
	    
	    if [ -d $KRN_WORKSPACE/${KRN_MODE}-linux-$Version ]
	    then
		echo "* ${KRN_MODE}-linux-$Version found in workspace, link $Version created"
		ln -s $KRN_WORKSPACE/${KRN_MODE}-linux-${Version} $Version
	    fi
	    ;;

	REDHAT)
	    # Recherche dans le repertoire de stockage (rpm)
	    PackageVersion=$Version
	    [ "$(echo $PackageVersion|cut -d. -f3)" = "" ] && PackageVersion=${PackageVersion}.0
	    
	    NbFound=$(ls -1 $KRN_WORKSPACE/kernel*-${PackageVersion}_*.rpm 2>/dev/null|wc -l)
	    if [ $NbFound -ge 2 ]
	    then
		echo "Version $PackageVersion : $NbFound packages available from $KRN_WORKSPACE"
		cp $KRN_WORKSPACE/kernel*-${PackageVersion}_*.rpm $PWD
	    fi
	    ;;	

	*)
	    # Paquets Debian / Ubuntu ... 
	    GetKernelPackage $Version 
    esac
done

echo   ""
printf "\033[44m GetKernel elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit 0