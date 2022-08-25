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
    GetKernel.sh $Version
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
    CompileSign_${KRN_MODE}.sh $KRN_WORKSPACE/linux-${Version}.tar.xz
    [ $? -ne 0 ] && exit 1
    
    # Installation du noyau
    # ---------------------
    InstallKernel_${KRN_MODE}.sh $Version
done

echo   ""
printf "\033[44m CompilInstall $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit $?
