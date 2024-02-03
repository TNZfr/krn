#!/bin/bash

. $KRN_EXE/_libkernel.sh

#-------------------------------------------------------------------------------
SignOneKernel ()
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
	    BootVmlinuz=/boot/vmlinuz-linux-custom
	    ModuleDirectory=/lib/modules/$ModuleDirectory
	    ;;
	
	*)
	    echo ""
	    echo "Provided parameter references $NbModule installed kernels."
	    echo $ModuleDirectory|tr [' '] ['\n']
	    echo ""
	    exit 1
    esac

    # Signature de vmlinuz
    # --------------------
    printh "Signing kernel $Version ..."
    echo "Memory tips : $KRNSB_PASS"
    $KRN_sudo sbsign             \
	      --key  $KRNSB_PRIV \
	      --cert $KRNSB_PEM  \
	      ${BootVmlinuz}
    
    mv -f ${BootVmlinuz}.signed ${BootVmlinuz}
    
    # Signature des modules installes
    # -------------------------------
    echo ""
    printh "Signing kernel modules $Version ..."
    CurrentDir=$PWD
    cd $ModuleDirectory

    export KBUILD_SIGN_PIN=$KRNSB_PASS
    [ "$LOGNAME" != "root" ] && KRN_sudo="sudo --preserve-env=KBUILD_SIGN_PIN"

    for ModuleBinary in $(find . -name "*.ko")
    do
	$KRN_sudo build/scripts/sign-file \
		  sha256                  \
		  $KRNSB_PRIV             \
		  $KRNSB_DER              \
		  $ModuleBinary
    done
    cd $CurrentDir
    printh "Done."
    echo ""
}

#-------------------------------------------------------------------------------
# Main
#

if [ $# -lt 1 ]
then
    echo ""
    echo "Syntax : ${KRN_Help_Prefix}Sign Version ..."
    echo "  Version  : number version (format x.y.z)"
    echo ""
    exit 1
fi

VerifySigningConditions

Debut=$(TopHorloge)
echo ""
for KernelVersion in $*
do
    SignOneKernel $KernelVersion
done

echo   ""
printf "\033[44m SignKernel $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit 0

