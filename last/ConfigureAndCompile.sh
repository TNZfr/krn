#!/bin/bash

. $KRN_EXE/_libkernel.sh

#-------------------------------------------------------------------------------
# main
#

CommandName=$(basename ${0%.sh})
if [ $# -lt 2 ]
then
    echo ""
    echo "Syntax : krn $CommandName Version|Archive Label|KernelConfig"
    echo ""
    echo "  Version .... : Linux version"
    echo "  Archive .... : Linux source archive (tar.xz or tar.gz)"
    echo "  Label ...... : Configuration label"
    echo "  KernelConfig : File generated by krn KernelConfig command (config-Version-Label)"
    echo ""
    exit 1
fi

Version=$1
Libelle=$2

# Conversion Archive -> Version (Cf KernelConfig -> GetKernel)
[ -f $Version ] && Version=$(echo ${Version%.tar.??}|cut -d'-' -f2-)

# Libelle ou KernelConfig
[ "${Libelle:0:7}" = "config-" ] && \
    [ $PWD != $KRN_WORKSPACE ]   && \
    [ ! -f $Libelle ]            && \
    Libelle=$KRN_WORKSPACE/$Libelle

if [ -f $Libelle ]
then
    FinalConfig=$(readlink -f $Libelle)
    [ "$(basename $Libelle|grep rc)" = "" ] && LabelField=3 || LabelField=4
    Libelle=$(basename $Libelle|cut -d'-' -f$LabelField)

    if [ "$Libelle" = "" ]
    then
	echo   ""
	echo   " ERROR : Bad filename format : $Libelle"
	printf " Expected : config-\033[32mVersion\033[m-\033[32mLabel\033[m\n"
	echo   ""
	exit 1
    fi
else
    FinalConfig=UnsetKernelConfig
fi 

Debut=$(TopHorloge)

# Configuration noyau
# -------------------
if [ $FinalConfig = UnsetKernelConfig ]
then
    KernelConfig.sh $Version $Libelle
    FinalConfig=$(ls -1tr $KRN_WORKSPACE/config-*-*|tail -1)
    if [ ! -f $FinalConfig ]
    then
	echo ""
	echo "No kernel config available in $KRN_WORKSPACE ."
	echo ""
	exit 1
    fi
fi
SetConfig.sh $FinalConfig >/dev/null

# Creation du workspace custom
# ----------------------------
[ "$(echo $Version|grep rc)" != "" ] \
    && CustomWorkspace=$KRN_WORKSPACE/ckc-$(echo $Version|cut -d'-' -f1).0-$(echo $Version|cut -d'-' -f2)-$Libelle \
    || CustomWorkspace=$KRN_WORKSPACE/ckc-$Version-$Libelle

mkdir -p $CustomWorkspace
export KRN_WORKSPACE=$CustomWorkspace

# Compilation du noyau
# --------------------
case $CommandName in
    ConfComp)         Compile_${KRN_MODE}.sh           $Version ;;
    ConfCompSign)     CompileSign_${KRN_MODE}.sh       $Version ;;
    ConfCompInstall)  CompilInstall_${KRN_MODE}.sh     $Version ;;
    ConfCompSignInst) CompilSignInstall_${KRN_MODE}.sh $Version ;;
    *)
	echo ""
	echo "Unkonwn krn command : $CommandName"
	echo ""
esac

# Retour a la config par defaut
# -----------------------------
SetConfig.sh DEFAULT >/dev/null

# Sauvegarde du fichier de config
# -------------------------------

echo ""
printf "\033[44m $CommandName elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo ""

exit 0