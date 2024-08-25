#!/bin/bash

. $KRN_EXE/lib/kernel.sh

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
    # Parsing linux version for archive and build format : KRN_LVBuild, KRN_LVArch, KRN_LVPackage, KRN_LVCkc
    ParseLinuxVersion $Version
    
    if [ $KRN_LVCkc = normal_release ] && [ "$KRN_CustomBuild" != "TRUE" ]
    then
	NbCKC=$(ls -1d $KRN_WORKSPACE/ckc-${KRN_LVBuild}-* 2>/dev/null|wc -l)
	if [ $NbCKC -gt 0 ]
	then
	    echo " $NbCKC Custom Kernel match(es) version $Version :"
	    for CustomKernel in $(ls -1d $KRN_WORKSPACE/ckc-${KRN_LVBuild}-*)
	    do
		printf "\t\033[35m$(basename $CustomKernel)\033[m\n"
	    done
	    echo ""
	    exit 1		    
	fi
    fi

    case $KRN_MODE in
	ARCH*)
	    if [ -L $KRN_LVBuild ]
	    then
		echo "* link already exists for ARCH-linux-$KRN_LVArch"
		continue
	    fi

	    _PackageDirectory=$KRN_WORKSPACE
	    [ $KRN_LVCkc != normal_release ] && _PackageDirectory=$KRN_WORKSPACE/$KRN_LVCkc
	    
	    # Historic ARCH-BuildDirectory
	    if [ -d $_PackageDirectory/ARCH-linux-$KRN_LVArch ]
	    then
		echo "* ARCH-linux-$KRN_LVArch found in workspace, link $KRN_LVBuild created"
		ln -s $_PackageDirectory/ARCH-linux-${KRN_LVArch} $KRN_LVBuild
		continue
	    fi

	    # KRN package (light build directory compressed)
	    NbFound=$(ls -1 $_PackageDirectory/linux-${KRN_LVArch}.krn.tar.zst 2>/dev/null|wc -l)
	    if [ $NbFound -ge 1 ]
	    then
		echo "Version $KRN_LVBuild : $NbFound packages available from $KRN_WORKSPACE"

		_RestoreDir=$PWD
		[ $(_GetDirectoryFreeMB $_RestoreDir) -lt 5120 ] && _RestoreDir=/tmp
		echo "Uncompressing in $_RestoreDir ..."
		
		zstdcat $_PackageDirectory/linux-${KRN_LVArch}.krn.tar.zst | tar xf - --directory=$_RestoreDir
		ln -s $_RestoreDir/linux-${KRN_LVArch} ${KRN_LVBuild}
		
		continue
	    fi

	    # ARCH Pacman package
	    NbFound=$(ls -1 $_PackageDirectory/linux-upstream-*${KRN_LVPackage}*.pkg.tar.zst 2>/dev/null|wc -l)
	    if [ $NbFound -ge 2 ]
	    then
		echo "Version $KRN_LVBuild : $NbFound packages available from $KRN_WORKSPACE"
		cp $_PackageDirectory/linux-upstream-*${KRN_LVPackage}*.pkg.tar.zst $PWD
		continue
	    fi
	    echo ""
	    echo "Linux version $KRN_LVArch (or $KRN_LVBuild) not found."
	    ;;

	REDHAT)
	    _PackageDirectory=$KRN_WORKSPACE
	    [ $KRN_LVCkc != normal_release ] && _PackageDirectory=$KRN_WORKSPACE/$KRN_LVCkc
	    
	    NbFound=$(ls -1 $_PackageDirectory/kernel*-${KRN_LVPackage}_*.rpm 2>/dev/null|wc -l)
	    if [ $NbFound -ge 2 ]
	    then
		echo "Version $KRN_LVBuild : $NbFound packages available from $KRN_WORKSPACE"
		cp $_PackageDirectory/kernel*-${KRN_LVPackage}_*.rpm $PWD
		continue
	    fi
	    echo ""
	    echo "Linux version $KRN_LVArch (or $KRN_LVBuild) not found."
	    ;;	

	DEBIAN)
	    # 1.Recherche dans le repertoire de stockage (deb)
	    PrevWorkspace=$KRN_WORKSPACE
	    [ $KRN_LVCkc != normal_release ] && export KRN_WORKSPACE=$KRN_WORKSPACE/$KRN_LVCkc

	    NbFound=$(ls -1 $KRN_WORKSPACE/linux-*$KRN_LVBuild*.deb 2>/dev/null|wc -l)
	    if [ $NbFound -ge 3 ]
	    then
		echo "Version $KRN_LVBuild : $NbFound packages available from $KRN_WORKSPACE"
		cp    $KRN_WORKSPACE/linux-*$KRN_LVBuild*.deb $PWD
		export KRN_WORKSPACE=$PrevWorkspace
		return 0
	    fi

	    # 2.Recherche sur Ubuntu/Mainline
	    if [ $KRN_LVCkc = normal_release ] && [ "$KRN_GetKernel" != "LocalOnly" ]
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
	    ;;

	*)
	    echo ""
	    echo "KRN mode $KRN_MODE non applicable."
	    echo ""
    esac
done

echo   ""
printf "\033[44m GetKernel elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit 0
