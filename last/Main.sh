#!/bin/bash

#-------------------------------------------------------------------------------
function RunCommand
{
    RunCommand_Name=$*
    AcctFile_Commande=$(for Name in $*; do echo ${Name%.ksh};done)
    AcctFile_Commande=$(echo $AcctFile_Commande|sed 's/ //g')

    # --------------------------------
    # Gestion de la LOG de la commande
    # --------------------------------
    KRN_FICACC="/dev/null"
    if [ -n "$KRN_ACCOUNTING" ] && [ -d $KRN_ACCOUNTING ]
    then
	KRN_FICACC=$KRN_ACCOUNTING/$(date +%Y%m%d-%Hh%Mm%Ss)-$AcctFile_Commande.log
	printf "\n\033[33;44m Command \033[m : krn $Commande $Parametre\n" > $KRN_FICACC
	chmod a+rw $KRN_FICACC
    fi

    if [ $KRN_FICACC = "/dev/null" ]
    then
	${RunCommand_Name} $Parametre
	Status=$?
    else
	StatusFile=/tmp/status-$$
	(${RunCommand_Name} $Parametre;echo $? > $StatusFile) | tee -a $KRN_FICACC
	Status=$(cat $StatusFile; rm -f $StatusFile)
    fi

    return $Status
}

#-------------------------------------------------------------------------------
# main
#

if [ $# -eq 0 ]
then
    echo   ""
    printf " \033[30;42m KRN v5.6 \033[m : Kernel management tool for Debian based, Redhat based and ArchLinux distributions"
    echo   ""
    echo   ""
    echo   ""
    printf "\033[37;44m Syntax \033[m : krn Command Parameters ...\n"
    echo  ""
    printf "\033[34m Workspace management \033[m\n"
    printf "\033[34m----------------------\033[m\n"
    echo  "Configure      (CF): Display parameters. To reset, run krn configure RESET"
    echo  "Purge              : Remove packages and kernel build directories from workspace"
    echo  ""
    printf "\033[34m Kernel from Local or Ubuntu/Mainline \033[m\n"
    printf "\033[34m--------------------------------------\033[m\n"
    echo  "List           (LS): List current kernel, installed kernel and available kernels from local"
    echo  "Search         (SE): Search available kernels from Kernel.org (and Ubuntu/Mainline in DEBIAN mode)"
    echo  "Get                : Get Debian packages from local (and Ubuntu/Mainline in DEBIAN mode)"
    echo  "Install            : Install selected kernel from local (and Ubuntu/Mainline in DEBIAN mode)"
    echo  "Sign           (SK): Sign installed kernel (DEBIAN only)"
    echo  "InstallSign    (IS): Install and sign selected kernel (DEBIAN only)"
    echo  "Remove             : Remove selected installed kernel"
    echo  ""
    printf "\033[34m Sources from kernel.org \033[m\n"
    printf "\033[34m-------------------------\033[m\n"
    echo  "ChangeLog           (CL): Get Linux changelog file from kernel.org and display selection"
    echo  "GetSource           (GS): Get Linux sources archive from kernel.org"
    echo  "Compile             (CC): Compile kernel"
    echo  "CompileSign        (CCS): Compile and sign kernel (DEBIAN only)"
    echo  "CompilInstall      (CCI): Get sources, compile and install kernel"
    echo  "CompilSignInstall (CCSI): Get sources, compile, sign and install kernel (DEBIAN only)"
    echo  ""
    printf "\033[34m Log management \033[m\n"
    printf "\033[34m----------------\033[m\n"
    echo "SaveLog (SL)      : Save logs in directory defined by KRN_ACCOUNTING"
    echo ""
    exit 0
fi

# Definition du repertoire des binaires
# -------------------------------------
export KRN_EXE=$(dirname $(readlink -f $0))
export PATH=$KRN_EXE:$PATH

# Chargement des variables
# ------------------------
. $KRN_EXE/Configure.sh LOAD
export KRN_MODE=$(        echo $KRN_MODE        |tr [:lower:] [:upper:])
export KRN_ARCHITECTURE=$(echo $KRN_ARCHITECTURE|tr [:upper:] [:lower:])
[ $LOGNAME = root ] && export KRN_sudo="" || export KRN_sudo="sudo"

# ---------------------
# Parsing des commandes
# ---------------------
Parametre=""
Commande=$(echo $1|tr [:upper:] [:lower:])
[ $# -gt 1 ] && Parametre="$(echo $*|cut -f2- -d' ')"

case $Commande in

    "configure" |"cf" ) RunCommand Configure.sh                     ;;
    "purge"           ) RunCommand Purge.sh                         ;;
    "list"       |"ls") RunCommand ListKernel.sh                    ;;
    "search"     |"se") RunCommand SearchKernel.sh                  ;;
    "get"        |"gk") RunCommand GetKernel.sh                     ;;
    "install"         ) RunCommand InstallKernel_${KRN_MODE}.sh     ;;
    "sign"       |"sk") RunCommand SignKernel_${KRN_MODE}.sh        ;;
    "installsign"|"is") RunCommand InstallSignKernel_${KRN_MODE}.sh ;;
    "remove"          ) RunCommand RemoveKernel_${KRN_MODE}.sh      ;;
    
    "changelog"        |"cl")   RunCommand ChangeLog.sh                     ;;
    "getsource"        |"gs")   RunCommand GetSource.sh                     ;;
    "compile"          |"cc")   RunCommand Compile_${KRN_MODE}.sh           ;;
    "compilinstall"    |"cci")  RunCommand CompilInstall_${KRN_MODE}.sh     ;;
    "compilesign"      |"ccs")  RunCommand CompileSign_${KRN_MODE}.sh       ;;
    "compilsigninstall"|"ccsi") RunCommand CompilSignInstall_${KRN_MODE}.sh ;;

    "savelog"      |"sl") SaveLog.sh ;;

    *)
	echo "Kernel management : Commande 'krn $1' inconnue."
	Status=1
esac

exit $Status
