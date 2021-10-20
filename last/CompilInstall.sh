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

# Initialisation des variables
InitVariable KRN_WORKSPACE dir "Workspace directory for package building and storage"
[ $LOGNAME = root ] && KRN_sudo="" || KRN_sudo="sudo"

Debut=$(TopHorloge)

for Version in $*
do
    # Verification avant compilation
    # ------------------------------
    NbPaquet=$(ls -1 $KRN_WORKSPACE/linux-*${Version}*.deb 2>/dev/null|wc -l)
    if [ $NbPaquet -ge 3 ]
    then
	echo "Package already built and available in workspace directory ..."
	$KRN_sudo dpkg -i --refuse-downgrade $KRN_WORKSPACE/linux-*${Version}*.deb
	continue
    fi
    
    # Telechargement des paquets
    # --------------------------
    GetSource.sh $Version
    
    # Generation des paquets Debian
    # -----------------------------
    GenPackage.sh $KRN_WORKSPACE/linux-${Version}.tar.xz
    [ $? -ne 0 ] && exit 1
    
    # Installation des paquets
    # ------------------------
    NbPaquet=$(ls -1 $KRN_WORKSPACE/linux-*${Version}*.deb 2>/dev/null|wc -l)
    if [ $NbPaquet -ge 3 ]
    then
	$KRN_sudo dpkg -i --refuse-downgrade $KRN_WORKSPACE/linux-*${Version}*.deb
    else
	echo "Not enough packages for $Version :"
	ls -1 $KRN_WORKSPACE/linux-*${Version}*.deb
	exit 1
    fi
done

echo   ""
printf "\033[44m CompilInstall elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit $?
