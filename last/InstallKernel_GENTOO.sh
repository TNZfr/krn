#!/bin/bash

. $KRN_EXE/_libkernel.sh

#-------------------------------------------------------------------------------
CheckStatus ()
{
    Status=$?
    [ $Status -eq 0 ] && return

    echo   ""
    echo   "ERROR : Return code $Status"
    echo   ""
    rm -rf $TempDir
    exit $Status
}

#-------------------------------------------------------------------------------
# Main
#
if [ $# -lt 1 ]
then
    echo ""
    echo "Syntax : krn Install Version ..."
    echo ""
    echo "  Version : as it appears in krn List output command"
    echo "            or just the version number"
    echo ""
    exit 1
fi

Debut=$(TopHorloge)
TempDir=$KRN_TMP/krn-$$
mkdir -p $TempDir
cd       $TempDir

# Telechargement des paquets
# --------------------------
GetKernel.sh $*
[ $? -ne 0 ] && exit 1
echo ""

# Installation des paquets
# ------------------------
for Version in $*
do
    if [ ${Version:0:3} = "ckc" ]
    then
	if [ "$(echo $Version|grep rc)" = "" ]
	then
	    Version=$(echo $Version|cut -d'-' -f2)
	else
	    Version=$(echo $Version|cut -d'-' -f2,3)
	fi
    fi
    
    [ ! -d $Version ] && continue
    cd $Version

    KernelVersion=$(make kernelversion)

    # Installation des modules
    printh "Linux $KernelVersion modules installation ..."
    $KRN_sudo make modules_install -j$(nproc)
    CheckStatus

    # Copie des fichiers dans /boot
    printh "Deploy vmlinuz-$KernelVersion ..."
    $KRN_sudo cp $(find arch -name bzImage -type f) /boot/vmlinuz-$KernelVersion
    CheckStatus
    
    printh "Deploy config-$KernelVersion ..."
    $KRN_sudo cp .config                            /boot/config-$KernelVersion
    CheckStatus
    
    printh "Build initrd.img-$KernelVersion ..."
    $KRN_sudo mkinitcpio -k $KernelVersion -g       /boot/initrd.img-$KernelVersion
    CheckStatus   

    #printh "DKMS modules build for $KernelVersion ..."
    #$KRN_sudo dkms autoinstall -k $KernelVersion
    #CheckStatus   

    echo ""
    cd $TempDir
done

# Mise a jour de GRUB
# -------------------
printh "GRUB update ..."
$KRN_sudo grub-mkconfig -o /boot/grub/grub.cfg
CheckStatus

# Menage de fin de traitement
# ---------------------------
rm -rf $TempDir

echo   ""
printf "\033[44m InstallKernel $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit 0
