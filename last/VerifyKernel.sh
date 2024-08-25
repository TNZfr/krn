#!/bin/bash

. $KRN_EXE/lib/kernel.sh

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
    case $KRN_MODE in
	ARCH)
	    for LinuxBinary in /boot/vmlinuz-*
	    do
		vmVersion=$(file $LinuxBinary              |\
				sed 's/version /version=/g'|\
				tr [' '] ['\n']            |\
				grep ^version              |\
				cut -d= -f2                  )		
		echo ""
		printf "\033[44m Kernel signature for $(basename $LinuxBinary) $vmVersion \033[m\n"
		sbverify -l $LinuxBinary
	    done
	    ;;

	*)
	    echo ""
	    printf "\033[44m Kernel signature for $Version \033[m\n"
	    sbverify -l /boot/vmlinuz-$(basename $ModuleDirectory)
	    ;;
    esac

    echo ""
    printf "\033[44m Module signature for $Version \033[m\n"
    Module=$ModuleDirectory/kernel/sound/soundcore.ko
    if [ -f ${Module}.xz ]
    then
	# Found in REDHAT distro
	xzcat ${Module}.xz > $KRN_TMP/${Version}-soundcore.ko
	Module=$KRN_TMP/${Version}-soundcore.ko

    elif [ -f ${Module}.zst ]
    then
	# Found in ARCH distro
	zstdcat ${Module}.zst > $KRN_TMP/${Version}-soundcore.ko
	Module=$KRN_TMP/${Version}-soundcore.ko
    fi    
    modinfo $Module
    echo ""
}

#-------------------------------------------------------------------------------
# Main
#

if [ $# -lt 1 ]
then
    [ "$KRN_CLI" = "" ] && _Prefix="krn "
    
    echo ""
    echo "Syntax : ${_Prefix}VerifyKernel Version ..."
    echo "  Version : number version (format x.y.z)"
    echo ""
    exit 1
fi

for KernelVersion in $*
do
    VerifyOneKernel $KernelVersion
done

exit 0

