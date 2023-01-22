#!/bin/bash

. $KRN_EXE/_libkernel.sh

#-------------------------------------------------------------------------------
# main
#

CommandName=$(basename ${0%.sh})
if [ $# -lt 2 ]
then
    echo ""
    echo "Syntax : krn $CommandName Version|Archive Label"
    echo ""
    echo "  Version : Linux version"
    echo "  Archive : Linux source archive (tar.xz or tar.gz)"
    echo "  Label   : Configuration label"
    echo ""
    exit 1
fi

Version=$1
Libelle=$2
[ -f $Version ] && Version=$(echo ${Version%.tar.??}|cut -d'-' -f2-)

Debut=$(TopHorloge)

# Creation du workspace custom
# ----------------------------
if [ "$(echo $Version|grep rc)" != "" ]
then
   CustomWorkspace=$KRN_WORKSPACE/ckc-$(echo $Version|cut -d'-' -f1).0-$(echo $Version|cut -d'-' -f2)-$Libelle
else
   CustomWorkspace=$KRN_WORKSPACE/ckc-$Version-$Libelle
fi
mkdir -p $CustomWorkspace
export KRN_WORKSPACE=$CustomWorkspace

# Configuration noyau
# -------------------
KernelConfig.sh $Version $Libelle
FinalConfig=$(ls -1tr $KRN_WORKSPACE/config-*-*|tail -1)
if [ ! -f $FinalConfig ]
then
    echo ""
    echo "No kernel config available in $KRN_WORKSPACE ."
    echo ""
    exit 1
fi
SetConfig.sh $FinalConfig >/dev/null

# Compilation du noyau
# --------------------
case $CommandName in
    ConfComp)         Compile_${KRN_MODE}.sh           $Version ;;
    ConfCompInstall)  CompilInstall_${KRN_MODE}.sh     $Version ;;
    ConfCompSign)     CompileSign_${KRN_MODE}.sh       $Version ;;
    ConfCompSignInst) CompilSignInstall_${KRN_MODE}.sh $Version ;;
    *)
	echo ""
	echo "Unkonwn krn command : $CommandName"
	echo ""
esac

# Retour a la config par defaut
# -----------------------------
SetConfig.sh DEFAULT >/dev/null

echo ""
printf "\033[44m $CommandName elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo ""

exit 0
