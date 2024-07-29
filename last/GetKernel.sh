#!/bin/bash

. $KRN_EXE/_libkernel.sh

#-------------------------------------------------------------------------------
GetKernelPackage ()
{
    # 1.Recherche dans le repertoire de stockage (deb)
    PrevWorkspace=$KRN_WORKSPACE
    if [ $KRN_LVCkc != normal_release ]
    then
	export KRN_WORKSPACE=$KRN_WORKSPACE/$KRN_LVCkc
    fi

    NbFound=$(ls -1 $KRN_WORKSPACE/linux-*$KRN_LVBuild*.deb 2>/dev/null|wc -l)
    if [ $NbFound -ge 3 ]
    then
	echo "Version $KRN_LVBuild : $NbFound packages available from $KRN_WORKSPACE"
	cp    $KRN_WORKSPACE/linux-*$KRN_LVBuild*.deb $PWD
	export KRN_WORKSPACE=$PrevWorkspace
	return 0
    fi

    # 2.Recherche sur Ubuntu/Mainline
    if [ $KRN_LVCkc = normal_release ]
    then
	GetKernelPackage_UbuntuMainline $KRN_LVArch
	NbFound=$?
	[ $NbFound -ge 4 ] && return 0

	if [ $NbFound -gt 0 ]
	then
	    echo "Not enough packages, file(s) removed."
	    rm -f linux-*$KRN_LVArch*.deb
	fi
    fi

    echo ""
    echo "Linux version $KRN_LVArch (or $KRN_LVBuild) not found."
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
	echo ""
	exit 1		    
    fi

    # Parsing linux version for archive and build format : KRN_LVBuild, KRN_LVArch
    ParseLinuxVersion $Version
    
    case $(echo $KRN_MODE|cut -d- -f1) in
	ARCH)
	    if [ -L $KRN_LVBuild ]
	    then
		echo "* link already exists for ARCH-linux-$KRN_LVBuild"
		continue
	    fi
	    
	    if [ -d $KRN_WORKSPACE/ARCH-linux-$KRN_LVBuild ]
	    then
		echo "* ARCH-linux-$KRN_LVBuild found in workspace, link $KRN_LVBuild created"
		ln -s $KRN_WORKSPACE/ARCH-linux-${KRN_LVBuild} $KRN_LVBuild
	    else
		exit 1
	    fi
	    ;;

	GENTOO)
	    if [ -L $KRN_LVBuild ]
	    then
		echo "* link already exists for ${KRN_MODE}-$KRN_LVBuild"
		continue
	    fi
	    
	    if [ -d $KRN_WORKSPACE/${KRN_MODE}-$KRN_LVBuild ]
	    then
		echo "* ${KRN_MODE}-$KRN_LVBuild found in workspace, link $KRN_LVBuild created"
		ln -s $KRN_WORKSPACE/${KRN_MODE}-${KRN_LVBuild} $KRN_LVBuild
	    else
		exit 1
	    fi
	    ;;

	REDHAT)
	    NbFound=$(ls -1 $KRN_WORKSPACE/kernel*-${KRN_LVBuild}_*.rpm 2>/dev/null|wc -l)
	    if [ $NbFound -ge 2 ]
	    then
		echo "Version $KRN_LVBuild : $NbFound packages available from $KRN_WORKSPACE"
		cp $KRN_WORKSPACE/kernel*-${KRN_LVBuild}_*.rpm $PWD
	    else
		exit 1
	    fi
	    ;;	

	*)
	    # Paquets Debian / Ubuntu ... 
	    GetKernelPackage $KRN_LVBuild 
    esac
done

echo   ""
printf "\033[44m GetKernel elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit 0
