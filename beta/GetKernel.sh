#!/bin/bash

. $KRN_EXE/_libkernel.sh

#-------------------------------------------------------------------------------
GetKernelPackage ()
{
    Version=$1
    [ $(echo $Version|cut -c1) = "v" ] && Version=$(echo $Version|cut -c2-)

    # 1.Recherche dans le repertoire de stockage (deb)
    PrevWorkspace=$KRN_WORKSPACE
    if [ ${Version:0:3} = "ckc" ]
    then
	export KRN_WORKSPACE=$KRN_WORKSPACE/$Version
	if [ "$(echo $Version|grep rc)" = "" ]
	then
	    Version=$(echo $Version|cut -d'-' -f2)
	else
	    Version=$(echo $Version|cut -d'-' -f2,3)
	fi
    fi

    NbFound=$(ls -1 $KRN_WORKSPACE/linux-*$Version*.deb 2>/dev/null|wc -l)
    if [ $NbFound -ge 3 ]
    then
	echo "Version $Version : $NbFound packages available from $KRN_WORKSPACE"
	cp $KRN_WORKSPACE/linux-*$Version*.deb $PWD
	export KRN_WORKSPACE=$PrevWorkspace
	return 0
    fi

    # 2.Recherche sur Ubuntu/Mainline
    if [ ${Version:0:3} != "ckc" ]
    then
	GetKernelPackage_UbuntuMainline $Version
	NbFound=$?
	[ $NbFound -ge 4 ] && return 0

	if [ $NbFound -gt 0 ]
	then
	    echo "Not enough packages, file(s) removed."
	    rm -f linux-*$Version*.deb
	fi
    fi

    echo ""
    echo "Linux version $Version not found."
}

#-------------------------------------------------------------------------------
GetKernelPackage_UbuntuMainline ()
{
    Version=$1

    Url=https://kernel.ubuntu.com/~kernel-ppa/mainline/v$Version/
    ListeDistante=$KRN_TMP/krn-ListeDistante-${Version}-$$.txt
    ListePaquets=$KRN_TMP/krn-ListePaquets-${Version}-$$.txt

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
    echo "Syntax : ${KRN_Help_Prefix}Get Version ..."
    echo ""
    echo "  Version : as it appears in krn List output command"
    echo "            or just the version number"
    echo ""
    exit 1
fi

Debut=$(TopHorloge)

echo ""
ListeVersion=$*
for Version in $ListeVersion
do
    # Misundersting filter
    NbCKC=$(ls -1d $KRN_WORKSPACE/ckc-$Version-* 2>/dev/null|wc -l)
    if [ $NbCKC -gt 0 ]
    then
	echo " $NbCKC Custom Kernel match(es) version $Version :"
	for CustomKernel in $(ls -1d $KRN_WORKSPACE/ckc-$Version-*)
	do
	    printf "\t\033[35m$(basename $CustomKernel)\033[m\n"
	done
	exit 1		    
    fi
    
    case $(echo $KRN_MODE|cut -d- -f1) in
	ARCH)
	    if [ -L $Version ]
	    then
		echo "* link already exists for ARCH-linux-$Version"
		continue
	    fi
	    
	    if [ ${Version:0:3} = "ckc" ]
	    then
		export KRN_WORKSPACE=$KRN_WORKSPACE/$Version
		
		if [ "$(echo $Version|grep rc)" = "" ]
		then
		    Version=$(echo $Version|cut -d'-' -f2)
		else
		    Version=$(echo $Version|cut -d'-' -f2,3)
		fi
	    fi
	    
	    if [ -d $KRN_WORKSPACE/ARCH-linux-$Version ]
	    then
		echo "* ARCH-linux-$Version found in workspace, link $Version created"
		ln -s $KRN_WORKSPACE/ARCH-linux-${Version} $Version
	    else
		exit 1
	    fi
	    ;;

	GENTOO)
	    if [ -L $Version ]
	    then
		echo "* link already exists for ${KRN_MODE}-$Version"
		continue
	    fi
	    
	    if [ ${Version:0:3} = "ckc" ]
	    then
		export KRN_WORKSPACE=$KRN_WORKSPACE/$Version
		
		if [ "$(echo $Version|grep rc)" = "" ]
		then
		    Version=$(echo $Version|cut -d'-' -f2)
		else
		    Version=$(echo $Version|cut -d'-' -f2,3)
		fi
	    fi
	    
	    if [ -d $KRN_WORKSPACE/${KRN_MODE}-$Version ]
	    then
		echo "* ${KRN_MODE}-$Version found in workspace, link $Version created"
		ln -s $KRN_WORKSPACE/${KRN_MODE}-${Version} $Version
	    else
		exit 1
	    fi
	    ;;

	REDHAT)
	    # Recherche dans le repertoire de stockage (rpm)
	    PackageVersion=$Version
	    [ "$(echo $PackageVersion|cut -d. -f3)" = "" ] && PackageVersion=${PackageVersion}.0
	    
	    if [ ${PackageVersion:0:3} = "ckc" ]
	    then
		export KRN_WORKSPACE=$KRN_WORKSPACE/$PackageVersion
		if [ "$(echo $Version|grep rc)" = "" ]
		then
		    PackageVersion=$(echo $PackageVersion|cut -d'-' -f2)
		else
		    PackageVersion=$(echo $PackageVersion|cut -d'-' -f2,3)
		fi
	    fi
	    
	    NbFound=$(ls -1 $KRN_WORKSPACE/kernel*-${PackageVersion}_*.rpm 2>/dev/null|wc -l)
	    if [ $NbFound -ge 2 ]
	    then
		echo "Version $PackageVersion : $NbFound packages available from $KRN_WORKSPACE"
		cp $KRN_WORKSPACE/kernel*-${PackageVersion}_*.rpm $PWD
	    else
		exit 1
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
