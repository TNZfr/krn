#!/bin/bash

. $KRN_EXE/_libkernel.sh
. $KRN_EXE/curses/_libcurses.sh

#-------------------------------------------------------------------------------
RemoveOneKernel ()
{
    Version=$1
    _Step=$2

    # Parsing /controle du parametre
    # ------------------------------
    _CursesStep debut REM${_Step} "\033[5;46m Running \033[m"
    ModuleDirectory=$(ls -1 /lib/modules|grep ^$Version 2>/dev/null)
    if [ "$ModuleDirectory" = "" ]
    then
	echo "Version $Version not installed."
	_CursesStep fin REM${_Step} "\033[31mNot installed\033[m"
	return
    fi
    
    NbModule=$(echo $ModuleDirectory|tr [' '] ['\n']|wc -l)
    case $NbModule in
	1)
	    if [ $(uname -r) = $ModuleDirectory ]
	    then
		echo "Version $(uname -r) is the current running kernel."
		echo "Can't be uninstalled while in use."
		_CursesStep fin REM${_Step} "\033[31mCurrent running kernel\033[m"
		return
	    fi
	    Version=$(echo $ModuleDirectory|cut -d'-' -f1,2)
	    ModuleDirectory=/lib/modules/$ModuleDirectory
	    ;;
	
	*)
	    echo ""
	    echo "Provided parameter references $NbModule installed kernels."
	    echo $ModuleDirectory|tr [' '] ['\n']
	    echo ""
	    _CursesStep fin REM${_Step} "\033[31m$NbModule installed kernels\033[m"
	    return
    esac

    echo ""
    echo "Uninstalling kernel $Version ..."
    echo ""

    # Suppression du noyau
    # --------------------
    Status=0
    PackageList=$(dpkg -l                          \
		       "linux-headers-${Version}*" \
		       "linux-image-*${Version}*"  \
		       "linux-modules-${Version}*" \
		       2>/dev/null | grep ^ii |cut -d' ' -f3)
    
    if [ "$PackageList" != "" ]
    then
	$KRN_sudo apt-get remove --purge $PackageList -y
	Status=$?
    fi
    
    # Nettoyage des restes de modules
    # -------------------------------
    if [ -d $ModuleDirectory ] && [ $Status -eq 0 ]
    then
	printf "Removing $ModuleDirectory ... "
	$KRN_sudo rm -rf $ModuleDirectory
	echo "done."
   fi
    _CursesStep fin REM${_Step} "\033[22;32m${Version} removed\033[m"
}

#-------------------------------------------------------------------------------
# Main
#

if [ $# -lt 1 ]
then
    echo ""
    echo "Syntax : ${KRN_Help_Prefix}Remove Version ..."
    echo "  Version : number version (format x.y.z)"
    echo ""
    exit 1
fi

#----------------------------------------
_CursesVar KRNC_PID=$$
#----------------------------------------

Debut=$(TopHorloge)
Param=1
for KernelVersion in $*
do
    RemoveOneKernel $KernelVersion $(printf "%02d" $Param)
    (( Param += 1))
done

ListInstalledKernel

printf "\033[44m RemoveKernel $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit 0

