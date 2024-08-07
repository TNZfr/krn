#!/bin/bash

. $KRN_EXE/_libkernel.sh
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
Param=1
for Version in $*
do
    export Step=$(printf "%02d" $Param)
    ((Param += 1))
    
    # Verification avant compilation
    # ------------------------------
    _CursesStep debut CCI${Step}a "\033[34m$Version\033[m \033[5;46m Running \033[m"
    PackageVersion=$Version
    if [ ${PackageVersion:0:3} = "ckc" ]
    then
	export KRN_WORKSPACE=$KRN_WORKSPACE/$PackageVersion
	if [ "$(echo $Version|grep rc)" = "" ]
	then
	    PackageVersion=$(echo $PackageVersion|cut -d'-' -f2)
	else
	    PackageVersion=$(echo $PackageVersion|cut -d'-' -f2,3)
	fi
    else
	[ "$(echo $PackageVersion|cut -d. -f3)" = "" ] && PackageVersion=${PackageVersion}.0
	[ "$(echo $Version|grep rc)" != "" ] && PackageVersion=${PackageVersion}-$(echo $Version|cut -d'-' -f2)
    fi
    
    NbPaquet=$(ls -1 $KRN_WORKSPACE/linux-*${PackageVersion}*.deb 2>/dev/null|wc -l)
    if [ $NbPaquet -ge 3 ]
    then
	_CursesStep fin CCI${Step}a "\033[34m$Version\033[m \033[22;32mFound in workspace\033[m"
	echo   ""
	printf "\033[34mPackage already built and available in workspace directory ...\033[m\n"
	echo   ""

	_CursesStep debut CCI${Step}c "\033[34m$Version\033[m \033[5;46m Running \033[m"
	$KRN_sudo dpkg -i --refuse-downgrade $KRN_WORKSPACE/linux-*${PackageVersion}*.deb
	_CursesStep fin CCI${Step}c "\033[34m$Version\033[m \033[22;32mInstalled\033[m"
	continue
    fi
     _CursesStep fin CCI${Step}a "\033[34m$Version\033[m \033[22;32mNo package available\033[m"
   
    # Telechargement des paquets
    # --------------------------
    _CursesStep debut CCI${Step}b "\033[34m$Version\033[m \033[5;46m Running \033[m"
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
    _CursesStep fin CCI${Step}b "\033[22;32m$(basename $KRN_WORKSPACE/linux-${Version}.tar.??)\033[m"

    Compile_${KRN_MODE}.sh $KRN_WORKSPACE/linux-${Version}.tar.??
    [ $? -ne 0 ] && exit 1
    
    # Installation des paquets
    # ------------------------
    _CursesStep debut CCI${Step}c "\033[34m$Version\033[m \033[5;46m Running \033[m"
    NbPaquet=$(ls -1 $KRN_WORKSPACE/linux-*${PackageVersion}*.deb 2>/dev/null|wc -l)
    if [ $NbPaquet -ge 3 ]
    then
	$KRN_sudo dpkg -i --refuse-downgrade $KRN_WORKSPACE/linux-*${PackageVersion}*.deb
	_CursesStep fin CCI${Step}c "\033[34m$Version\033[m \033[22;32mInstalled\033[m"
    else
	_CursesStep fin CCI${Step}c "\033[34m$Version\033[m \033[31mFAILED\033[m"
	echo "Not enough packages for $PackageVersion :"
	ls -1 $KRN_WORKSPACE/linux-*${PackageVersion}*.deb
    fi
done

echo   ""
printf "\033[44m CompileInstall $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit $?
