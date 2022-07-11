#!/bin/bash

. $KRN_EXE/_libkernel.sh

#-------------------------------------------------------------------------------
RemoveOneKernel ()
{
    Version=$1

    # Parsing /controle du parametre
    # ------------------------------
    ModuleDirectory=$(ls -1 /lib/modules|grep ^$Version 2>/dev/null)
    if [ "$ModuleDirectory" = "" ]
    then
	echo "Version $Version not installed."
	exit 1
    fi
    
    NbModule=$(echo $ModuleDirectory|tr [' '] ['\n']|wc -l)
    case $NbModule in
	1)
	    if [ $(uname -r) = $ModuleDirectory ]
	    then
		echo "Kernel $(uname -r) is the current running kernel."
		echo "Can't be uninstalled while in use."
		exit 1
	    fi
	    Version=$(echo $ModuleDirectory|cut -d'-' -f1,2)
	    ModuleDirectory=/lib/modules/$ModuleDirectory
	    ;;
	
	*)
	    echo ""
	    echo "Provided parameter references $NbModule installed kernels."
	    echo $ModuleDirectory|tr [' '] ['\n']
	    echo ""
	    exit 1
    esac

    echo ""
    echo "Uninstalling kernel $Version ..."
    echo ""

    # Suppression du noyau 
    # --------------------
    Status=1
    PackageList=$(rpm -qa|grep ^kernel|grep $(echo $Version|cut -d- -f1))
    
    if [ "$PackageList" != "" ]
    then
	$KRN_sudo yum remove -y $PackageList ; Status=$?
	$KRN_sudo grub2-mkconfig -o /boot/grub2/grub.cfg
    fi
    
    # Nettoyage des restes de modules
    # -------------------------------
    if [ -d $ModuleDirectory ] && [ $Status -eq 0 ]
    then
	printf "Removing $ModuleDirectory ... "
	$KRN_sudo rm -rf $ModuleDirectory
	echo "done."
    fi
}

#-------------------------------------------------------------------------------
# Main
#

if [ $# -lt 1 ]
then
    echo ""
    echo "Syntax : krn Remove Version ..."
    echo "  Version : number version (format x.y.z)"
    echo ""
    exit 1
fi

Debut=$(TopHorloge)
for KernelVersion in $*
do
    RemoveOneKernel $KernelVersion
done

echo ""
echo "Installed kernel(s)"
echo "-------------------"
linux-version sort $(ls -1 /lib/modules)
echo   ""
printf "\033[44m RemoveKernel $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit 0

