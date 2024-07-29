#!/bin/bash

. $KRN_EXE/_libkernel.sh
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

Param=1
for Version in $*
do
    export Step=$(printf "%02d" $Param)
    ((Param += 1))
    
    # Verification avant compilation
    # ------------------------------
    _CursesStep debut CCSI${Step}b "\033[34m$Version\033[m \033[5;46m Running \033[m"
    PackageVersion=$Version
    [ "$(echo $PackageVersion|cut -d. -f3)" = "" ] && PackageVersion=${PackageVersion}.0
    [ "$(echo $Version|grep rc)" != "" ] && PackageVersion=${PackageVersion}-$(echo $Version|cut -d'-' -f2)
    NbPaquet=$(ls -1 $KRN_WORKSPACE/linux-*${PackageVersion}*.deb 2>/dev/null|wc -l)
    if [ $NbPaquet -ge 3 ]
    then
	_CursesStep fin CCSI${Step}b "\033[34m$Version\033[m \033[22;32mFound in workspace\033[m"
	echo   ""
	printf "\033[34mPackage already built and available in workspace directory ...\033[m\n"
	echo   ""

	_CursesStep debut CCSI${Step}d "\033[34m$Version\033[m \033[5;46m Running \033[m"
	$KRN_sudo dpkg -i --refuse-downgrade $KRN_WORKSPACE/linux-*${PackageVersion}*.deb
	_CursesStep fin CCSI${Step}d "\033[34m$Version\033[m \033[22;32mInstalled\033[m"
	continue
    fi
    _CursesStep fin CCSI${Step}b "\033[34m$Version\033[m \033[22;32mNo package available\033[m"
     
    # Telechargement des paquets
    # --------------------------
    _CursesStep debut CCSI${Step}c "\033[34m$Version\033[m \033[5;46m Running \033[m"
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
    _CursesStep fin CCSI${Step}c "\033[22;32m$(basename $KRN_WORKSPACE/linux-${Version}.tar.??)\033[m"

    CompileSign_${KRN_MODE}.sh $KRN_WORKSPACE/linux-${Version}.tar.??
    [ $? -ne 0 ] && return 1
    
    # Installation des paquets
    # ------------------------
    _CursesStep debut CCSI${Step}d "\033[34m$Version\033[m \033[5;46m Running \033[m"
    NbPaquet=$(ls -1 $KRN_WORKSPACE/linux-*${PackageVersion}*.deb 2>/dev/null|wc -l)
    if [ $NbPaquet -ge 3 ]
    then
	$KRN_sudo dpkg -i --refuse-downgrade $KRN_WORKSPACE/linux-*${PackageVersion}*.deb
	_CursesStep fin CCSI${Step}d "\033[34m$Version\033[m \033[22;32mInstalled\033[m"
    else
	echo "Not enough packages for $PackageVersion :"
	ls -1 $KRN_WORKSPACE/linux-*${PackageVersion}*.deb
	_CursesStep fin CCSI${Step}d "\033[34m$Version\033[m \033[31mFAILED\033[m"
	return 1
    fi
done

echo   ""
printf "\033[44m CompileSignInstall $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit $?
