#!/bin/bash

. $KRN_EXE/_libkernel.sh

#-------------------------------------------------------------------------------
VerifyOneKernel ()
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

    # Verification du noyau
    # ---------------------
    echo ""
    printf "\033[44m Kernel signature for $Version \033[m\n"
    if [ $KRN_MODE = ARCH-CUSTOM ]
    then
	sbverify -l /boot/vmlinuz-linux-custom
    else
	sbverify -l /boot/vmlinuz-$(basename $ModuleDirectory)
    fi
    echo ""
    printf "\033[44m Module signature for $Version \033[m\n"
    modinfo $ModuleDirectory/kernel/sound/soundcore.ko
    echo ""
}

#-------------------------------------------------------------------------------
# Main
#

if [ $# -lt 1 ]
then
    echo ""
    echo "Syntax : krn VerifyKernel Version ..."
    echo "  Version : number version (format x.y.z)"
    echo ""
    exit 1
fi

for KernelVersion in $*
do
    VerifyOneKernel $KernelVersion
done

exit 0

