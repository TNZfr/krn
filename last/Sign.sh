#!/bin/bash

. $KRN_EXE/lib/kernel.sh && LoadModule
. $KRN_EXE/curses/_libcurses.sh

#-------------------------------------------------------------------------------
SignOneKernel ()
{
    Version=$1
    _Step=$2
    
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
	    BootVmlinuz=/boot/vmlinuz-$ModuleDirectory
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
    _CursesStep debut SIG${_Step}a "\033[5;46m Running \033[m"
    printh "Signing kernel $Version ..."
    echo "Memory tips : $KRNSB_PASS"
    $KRN_sudo sbsign             \
	      --key  $KRNSB_PRIV \
	      --cert $KRNSB_PEM  \
	      ${BootVmlinuz}
    
    $KRN_sudo mv -f ${BootVmlinuz}.signed ${BootVmlinuz}
    _CursesStep fin SIG${_Step}a "\033[22;32mDone\033[m"
   
    # Signature des modules installes
    # -------------------------------
    echo ""
    _CursesStep debut SIG${_Step}b "\033[5;46m Running \033[m"
    printh "Signing kernel modules $Version ..."
    CurrentDir=$PWD
    cd $ModuleDirectory

    export KBUILD_SIGN_PIN=$KRNSB_PASS
    [ "$LOGNAME" != "root" ] && KRN_sudo="sudo --preserve-env=KBUILD_SIGN_PIN"

    for ModuleBinary in $(find . -name "*.ko*")
    do
	# uncompress if needed
	ModuleFile=$(basename $ModuleBinary)
	if [ ${ModuleFile%.ko.zst} != $ModuleFile ]
	then
	    unzstd ${Module}
	    rm     ${Module}
	    Module=${Module%.ko.zst}
	    
	elif [ ${ModuleFile%.ko.xz} != $ModuleFile ]
	then
	    unxz ${Module}
	fi
	
	$KRN_sudo build/scripts/sign-file \
		  sha256                  \
		  $KRNSB_PRIV             \
		  $KRNSB_DER              \
		  $ModuleBinary
	
	# Recompress if needed
	if [ ${ModuleFile%.ko.zst} != $ModuleFile ]
	then
	    zstd ${Module}
	    rm   ${Module}
	    
	elif [ ${ModuleFile%.ko.xz} != $ModuleFile ]
	then
	    xz ${Module}
	fi
    done
    cd $CurrentDir
    printh "Done."
    _CursesStep fin SIG${_Step}b "\033[22;32mDone\033[m"
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
Debut=$(TopHorloge)

_CursesStep debut SIG01 "\033[5;46m Running \033[m"
VerifySigningConditions
case $? in
    1) _CursesStep fin SIG01 "\033[31mParameter not defined\033[m"         ; exit 1;;
    2) _CursesStep fin SIG01 "\033[31mOne or more missing parameter\033[m" ; exit 1;;
    3) _CursesStep fin SIG01 "\033[31mMissing file(s)\033[m"               ; exit 1;;
esac
_CursesStep fin SIG01 "\033[22;32mFound\033[m"

# Installation des prerequis
# --------------------------
_CursesStep  debut SIG02 "\033[5;46m Running \033[m"
_VerifyTools COMPIL
_CursesStep  fin   SIG02 "\033[22;32mInstalled\033[m"

echo ""
StepNum=3
for KernelVersion in $*
do
    SignOneKernel $KernelVersion $(printf "%02d" $StepNum)
    (( StepNum += 1))
done

# Mise a jour de GRUB par securite
# --------------------------------
_CursesStep debut SIG04 "\033[5;46m Running \033[m"
printh "GRUB update ..."
_UpdateGrub
_CursesStep fin SIG04 "\033[22;32mDone\033[m"

echo   ""
printf "\033[44m Sign $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit 0

