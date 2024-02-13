#!/bin/bash

. $KRN_EXE/_libkernel.sh
. $KRN_EXE/curses/_libcurses.sh

#-------------------------------------------------------------------------------
# main
#

CommandName=$(basename ${0%.sh})
if [ $# -lt 2 ]
then
    echo ""
    echo "Syntax : ${KRN_Help_Prefix}$CommandName Version|Archive KernelConfig"
    echo ""
    echo "  Version .... : Linux version"
    echo "  Archive .... : Linux source archive (tar.xz or tar.gz)"
    echo "  KernelConfig : File generated by krn KernelConfig command (config-Version-Label)"
    echo ""
    exit 1
fi

Version=$1
KernelConfig=$KRN_WORKSPACE/$2

#----------------------------------------
_CursesVar KRNC_PID=$$
#----------------------------------------
_CursesStep debut KCC01 "\033[5;46m Running \033[m"

# Conversion Archive -> Version (Cf KernelConfig -> GetKernel)
[ -f $Version ] && Version=$(echo ${Version%.tar.??}|cut -d'-' -f2-)

# KernelConfig
if [ ! -f $KernelConfig ]
then
    echo ""
    echo "ERROR : $(basename $KernelConfig) not found"
    echo ""
    exit 1
fi
KernelConfig=$(readlink -f $KernelConfig)
[ "$(basename $KernelConfig|grep rc)" = "" ] && LabelField=3 || LabelField=4
Libelle=$(basename $KernelConfig|cut -d'-' -f$LabelField)

Debut=$(TopHorloge)

# Configuration noyau
# -------------------
KernelSource=$(ls -1tr $KRN_WORKSPACE/linux-$Version.tar.?? 2>/dev/null|tail -1)

# Creation du workspace custom
# ----------------------------
if [ "$(echo $Version|grep rc)" = "" ]
then
    CustomWorkspace=$KRN_WORKSPACE/ckc-$Version-$Libelle
else
    CustomWorkspace=$KRN_WORKSPACE/ckc-$(echo $Version|cut -d'-' -f1).0-$(echo $Version|cut -d'-' -f2)-$Libelle
fi

mkdir -p $CustomWorkspace
export KRN_WORKSPACE=$CustomWorkspace

# Setting kernel config file
ln -s $KernelConfig $KRN_WORKSPACE/CompilConfig

# Source already downloaded
[ "$KernelSource" != "" ] && ln -s $KernelSource $KRN_WORKSPACE/$(basename $KernelSource)

_CursesStep fin KCC01 "\033[22;32m$(basename $KRN_WORKSPACE)\033[m"

# Compilation du noyau
# --------------------
case $CommandName in
    ConfComp)         Compile_${KRN_MODE}.sh            $Version ;;
    ConfCompSign)     CompileSign_${KRN_MODE}.sh        $Version ;;
    ConfCompInstall)  CompileInstall_${KRN_MODE}.sh     $Version ;;
    ConfCompSignInst) CompileSignInstall_${KRN_MODE}.sh $Version ;;
    *)
	echo ""
	echo "Unkonwn krn command : $CommandName"
	echo ""
esac

# Cleaning custom workspace
rm -f $KRN_WORKSPACE/CompilConfig

echo ""
printf "\033[44m $CommandName elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo ""

exit 0