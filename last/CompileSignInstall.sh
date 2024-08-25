#!/bin/bash

. $KRN_EXE/lib/kernel.sh && LoadModule
. $KRN_EXE/curses/_libcurses.sh

if [ $# -lt 1 ]
then
    echo ""
    echo "Syntax : ${KRN_Help_Prefix}CompileSignInstall Version ..."
    echo ""
    echo "  Version : as it appears in krn List output command"
    echo "            or just the version number"
    echo ""
    exit 1
fi

Debut=$(TopHorloge)

# Controle des elements de signature
# ----------------------------------
_CursesStep debut CCSI01 "\033[5;46m Running \033[m"
VerifySigningConditions
case $? in
    1) _CursesStep fin CCSI01 "\033[31mParameter not defined\033[m"         ; exit 1;;
    2) _CursesStep fin CCSI01 "\033[31mOne or more missing parameter\033[m" ; exit 1;;
    3) _CursesStep fin CCSI01 "\033[31mMissing file(s)\033[m"               ; exit 1;;
esac
_CursesStep fin CCSI01 "\033[22;32mFound\033[m"

CurrentDirectory=$PWD;
export    TmpDir=$KRN_TMP/GetKernel-$$;
mkdir -p $TmpDir
cd       $TmpDir

Param=1
for Version in $*
do
    export Step=$(printf "%02d" $Param)
    ((Param += 1))
    
    # Verification avant compilation
    # ------------------------------
    _CursesStep debut CCSI${Step}b "\033[34m$Version\033[m \033[5;46m Running \033[m"

    ParseLinuxVersion $Version
    

    KRN_GetKernel=LocalOnly GetKernel.sh $KRN_LVBuild

    if [ $(_CheckPackage) = OK ]
    then
	_CursesStep fin CCSI${Step}b "\033[34m$Version\033[m \033[22;32mFound in workspace\033[m"
	echo   ""
	printf "\033[34mPackage already built and available in workspace directory ...\033[m\n"
	echo   ""

	_CursesStep debut CCSI${Step}d "\033[34m$Version\033[m \033[5;46m Running \033[m"
	_InstallPackage
	_CursesStep fin CCSI${Step}d "\033[34m$Version\033[m \033[22;32mInstalled\033[m"
	
	cd $CurrentDirectory; _CleanTempDirectory $TmpDir

	continue
    fi
    cd $CurrentDirectory; _CleanTempDirectory $TmpDir
    
    _CursesStep fin CCSI${Step}b "\033[34m$Version\033[m \033[22;32mNo package available\033[m"
     
    # Telechargement des paquets
    # --------------------------
    _CursesStep debut CCSI${Step}c "\033[34m$Version\033[m \033[5;46m Running \033[m"
    GetSource.sh $Version
    
    # Generation des paquets
    # ----------------------
    _CursesStep fin CCSI${Step}c "\033[22;32m$(basename $KRN_WORKSPACE/linux-${KRN_LVArch}.tar.??)\033[m"

    CompileSign.sh $KRN_WORKSPACE/linux-${KRN_LVArch}.tar.??
    [ $? -ne 0 ] && return 1
    
    # Installation des paquets
    # ------------------------
    _CursesStep debut CCSI${Step}d "\033[34m$Version\033[m \033[5;46m Running \033[m"

    _CleanTempDirectory $TmpDir
    KRN_GetKernel=LocalOnly GetKernel.sh $KRN_LVBuild

    if [ $(_CheckPackage) = OK ]
    then
	_InstallPackage
	_CursesStep fin CCSI${Step}d "\033[34m$Version\033[m \033[22;32mInstalled\033[m"
    else
	_CursesStep fin CCSI${Step}d "\033[34m$Version\033[m \033[31mFAILED\033[m"
	echo "Not enough packages for ${KRN_LVBuild} :"
	ls -1 $TmpDir
    fi

    cd $CurrentDirectory
    _CleanTempDirectory $TmpDir
done

_RemoveTempDirectory $TmpDir

echo   ""
printf "\033[44m CompileSignInstall $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit $?
