#!/bin/bash

. $KRN_EXE/_libkernel.sh

if [ $# -lt 1 ]
then
    echo ""
    echo "Syntax : krn CompilInstall Version ..."
    echo ""
    echo "  Version : as it appears in krn List output command"
    echo "            or just the version number"
    echo ""
    exit 1
fi

Debut=$(TopHorloge)

for Version in $*
do
    # Verification avant compilation
    # ------------------------------
    PackageVersion=$Version
    [ "$(echo $PackageVersion|cut -d. -f3)" = "" ] && PackageVersion=${PackageVersion}.0
    [ "$(echo $Version|grep rc)" != "" ] && PackageVersion=${PackageVersion}-$(echo $Version|cut -d'-' -f2)
    NbPaquet=$(ls -1 $KRN_WORKSPACE/kernel-*${PackageVersion}*.rpm 2>/dev/null|wc -l)
    if [ $NbPaquet -ge 2 ]
    then
	echo   ""
	printf "\033[34mPackage already built and available in workspace directory ...\033[m\n"
	echo   ""

	$KRN_sudo yum install -y $KRN_WORKSPACE/kernel-*${PackageVersion}*.rpm
	$KRN_sudo grub2-mkconfig -o /boot/grub2/grub.cfg
	continue
    fi
    
    # Telechargement des paquets
    # --------------------------
    GetSource.sh $Version
    
    # Generation des paquets Debian
    # -----------------------------
    ArchiveName=$(basename $KRN_WORKSPACE/linux-${Version}.tar.??)
    ArchiveName=${ArchiveName%.tar.??}
    if [ "$(echo $ArchiveName|grep rc)" != "" ]
    then
	PackageVersion=$(echo $ArchiveName|cut -d- -f2|cut -d. -f1,2).0-$(echo $ArchiveName|cut -d- -f3)
    else
	PackageVersion=$(echo $ArchiveName|cut -d- -f2|cut -d. -f1-3)
	[ "$(echo $PackageVersion|cut -d. -f3)" = "" ] && PackageVersion=$(echo $PackageVersion|cut -d. -f1,2).0
    fi
    
    Compile_${KRN_MODE}.sh $KRN_WORKSPACE/linux-${Version}.tar.??
    [ $? -ne 0 ] && exit 1
    
    # Installation des paquets
    # ------------------------
    NbPaquet=$(ls -1 $KRN_WORKSPACE/kernel-*${PackageVersion}*.rpm 2>/dev/null|wc -l)
    if [ $NbPaquet -ge 2 ]
    then
	$KRN_sudo yum install -y $KRN_WORKSPACE/kernel-*${PackageVersion}_*.rpm
	$KRN_sudo grub2-mkconfig -o /boot/grub2/grub.cfg
    else
	echo "Not enough packages for $PackageVersion :"
	ls -1 $KRN_WORKSPACE/kernel-*${PackageVersion}_*.rpm
	exit 1
    fi
done

echo   ""
printf "\033[44m CompilInstall $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit $?
