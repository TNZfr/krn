#!/bin/bash

. $KRN_EXE/lib/kernel.sh && LoadModule
. $KRN_EXE/curses/_libcurses.sh

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

CurrentDirectory=$PWD
export    TmpDir=$KRN_TMP/CompilInstall-$$
mkdir -p $TmpDir
cd       $TmpDir

Param=1
for Version in $*
do
    export Step=$(printf "%02d" $Param)
    ((Param += 1))
    
    # Verification avant compilation
    # ------------------------------
    _CursesStep debut CCI${Step}a "\033[34m$Version\033[m \033[5;46m Running \033[m"

    ParseLinuxVersion $Version
    KRN_GetKernel=LocalOnly GetKernel.sh $KRN_LVBuild

    if [ $(_CheckPackage) = OK ]
    then
	_CursesStep fin CCI${Step}a "\033[34m$Version\033[m \033[22;32mFound in workspace\033[m"
	echo   ""
	printf "\033[34mPackage already built and available in workspace directory ...\033[m\n"
	echo   ""

	_CursesStep debut CCI${Step}c "\033[34m$Version\033[m \033[5;46m Running \033[m"
	_InstallPackage
	_CursesStep fin CCI${Step}c "\033[34m$Version\033[m \033[22;32mInstalled\033[m"
	
	_CleanTempDirectory $TmpDir

	continue
    fi
    _CleanTempDirectory $TmpDir
    
    _CursesStep fin CCI${Step}a "\033[34m$Version\033[m \033[22;32mNo package available\033[m"
   
    # Telechargement des paquets
    # --------------------------
    _CursesStep debut CCI${Step}b "\033[34m$Version\033[m \033[5;46m Running \033[m"
    GetSource.sh $Version

    # Generation des paquets
    # ----------------------
    _CursesStep fin CCI${Step}b "\033[22;32m$(basename $KRN_WORKSPACE/linux-${KRN_LVArch}.tar.??)\033[m"

    Compile.sh $KRN_WORKSPACE/linux-${KRN_LVArch}.tar.??
    if [ $? -ne 0 ]
    then
	_RemoveTempDirectory $TmpDir
	exit 1
    fi
    
    # Installation des paquets
    # ------------------------
    _CursesStep debut CCI${Step}c "\033[34m${KRN_LVBuild}\033[m \033[5;46m Running \033[m"

    _CleanTempDirectory $TmpDir
    KRN_GetKernel=LocalOnly GetKernel.sh $KRN_LVBuild

    if [ $(_CheckPackage) = OK ]
    then
	_InstallPackage
	_CursesStep fin CCI${Step}c "\033[34m$Version\033[m \033[22;32mInstalled\033[m"
    else
	_CursesStep fin CCI${Step}c "\033[34m$Version\033[m \033[31mFAILED\033[m"
	echo "Not enough packages for ${KRN_LVBuild} :"
	ls -1 $TmpDir
    fi

    _CleanTempDirectory $TmpDir
done

_RemoveTempDirectory $TmpDir

echo   ""
printf "\033[44m CompileInstall $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit $?
