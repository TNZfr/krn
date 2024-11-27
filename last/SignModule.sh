#!/bin/bash

. $KRN_EXE/lib/kernel.sh && LoadModule
. $KRN_EXE/curses/_libcurses.sh

#-------------------------------------------------------------------------------
SignOneModule ()
{
    ModuleDirectory=$1
    Module=$2
    _Step=$3
    
    # Signature du module
    # -------------------
    _CursesStep debut SIM${_Step} "\033[5;46m Running \033[m"
    printh "Signing kernel module $Module ..."

    # If module name instead of module file
    [ ! -f $ModuleDirectory/$Module ] && Module=$(find $ModuleDirectory -name "${Module}.ko*")

    # uncompress if needed
    ModuleFile=$(basename $Module)
    if [ ${ModuleFile%.ko.zst} != $ModuleFile ]
    then
	unzstd ${Module}
	rm     ${Module}
	Module=${Module%.ko.zst}
	
    elif [ ${ModuleFile%.ko.xz} != $ModuleFile ]
    then
	unxz ${Module}
    fi

    export KBUILD_SIGN_PIN=$KRNSB_PASS
    [ "$LOGNAME" != "root" ] && KRN_sudo="sudo --preserve-env=KBUILD_SIGN_PIN"

    $KRN_sudo $ModuleDirectory/build/scripts/sign-file \
		  sha256 $KRNSB_PRIV $KRNSB_DER $Module

    # Recompress if needed
    if [ ${ModuleFile%.ko.zst} != $ModuleFile ]
    then
	zstd ${Module}
	rm   ${Module}
	
    elif [ ${ModuleFile%.ko.xz} != $ModuleFile ]
    then
	xz ${Module}
    fi
    
    printh "Done."
    _CursesStep fin SIM${_Step} "\033[22;32mDone\033[m"
    echo ""
}

#-------------------------------------------------------------------------------
# Main
#

if [ $# -lt 2 ]
then
    echo ""
    echo "Syntax : ${KRN_Help_Prefix}SignModule Version ModuleFile ..."
    echo "  Version ... : number version (format x.y.z)"
    echo "  ModuleFile  : Module file (.ko)"
    echo ""
    exit 1
fi
Debut=$(TopHorloge)

KernelVersion=$1
ModuleList=$(echo $*|cut -d' ' -f2-)

# Parsing /controle du parametre
# ------------------------------
ModuleDirectory=$(ls -1 /lib/modules|grep ^$KernelVersion 2>/dev/null)
if [ "$ModuleDirectory" = "" ]
then
    echo "Version $Version not installed."
    exit 1
fi
ModuleDirectory=/lib/modules/$ModuleDirectory

_CursesStep debut SIM01 "\033[5;46m Running \033[m"
VerifySigningConditions
case $? in
    1) _CursesStep fin SIM01 "\033[31mParameter not defined\033[m"         ; exit 1;;
    2) _CursesStep fin SIM01 "\033[31mOne or more missing parameter\033[m" ; exit 1;;
    3) _CursesStep fin SIM01 "\033[31mMissing file(s)\033[m"               ; exit 1;;
esac
_CursesStep fin SIM01 "\033[22;32mFound\033[m"

# Installation des prerequis
# --------------------------
_CursesStep  debut SIM02 "\033[5;46m Running \033[m"
_VerifyTools COMPIL
_CursesStep  fin   SIM02 "\033[22;32mInstalled\033[m"

echo ""
StepNum=3
for Module in $ModuleList
do
    SignOneModule $ModuleDirectory $Module $(printf "%02d" $StepNum)
    (( StepNum += 1))
done

echo   ""
printf "\033[44m SignModule $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit 0

