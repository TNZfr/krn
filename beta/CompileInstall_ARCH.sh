#!/bin/bash

. $KRN_EXE/_libkernel.sh

if [ $# -lt 1 ]
then
    echo ""
    echo "Syntax : ${KRN_Help_Prefix}CompileInstall Version ..."
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
    GetKernel.sh $Version
    [ $? -ne 0 ] && exit 1
    if [ -L $Version ]
    then
	echo   ""
	printf "\033[34mKernel already built and available in workspace directory ...\033[m\n"
	echo   ""
	InstallKernel_${KRN_MODE}.sh $Version
	continue
    fi
    
    # Telechargement des paquets
    # --------------------------
    GetSource.sh $Version
    
    # Compilation du noyau
    # --------------------
    Compile_${KRN_MODE}.sh $KRN_WORKSPACE/linux-${Version}.tar.??
    [ $? -ne 0 ] && exit 1
    
    # Installation du noyau
    # ---------------------
    InstallKernel_${KRN_MODE}.sh $Version
done

echo   ""
printf "\033[44m CompileInstall $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit $?
