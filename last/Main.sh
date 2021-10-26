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
	echo "\n\033[33;44m Command \033[m : clussh $Commande $Parametre\n" > $KRN_FICACC
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
    printf "\033[37;44m Syntax \033[m : krn Command Parameters ...\n"
    echo  ""
    printf "\033[34;47m Package from Local or Ubuntu/Mainline \033[m\n"
    echo              "---------------------------------------"
    echo  "List           (LS): List available kernels from local and Ubuntu/Mainline"
    echo  "Get                : Get Debian packages from local or Ubuntu/Mainline"
    echo  "Install            : Install selected kernel from local or Ubuntu/Mainline"
    echo  "Remove             : Remove selected installed kernel"
    echo  ""
    printf "\033[34;47m Sources from kernel.org \033[m\n"
    echo              "-------------------------"
    echo  "ChangeLog      (CL): Get Linux changelog file from kernel.org and display selection"
    echo  "GetSource      (GS): Get Linux sources archive from kernel.org"
    echo  "GenPackage     (GP): Compile and generate Debian packages"
    echo  "CompilInstall (CCI): Get sources, generate Debian packages and install kernel"
    echo  ""
    exit 0
fi

# Definition du repertoire des binaires
# -------------------------------------
export KRN_EXE=$(dirname $(readlink -f $0))
export PATH=$KRN_EXE:$PATH

# Chargement des variables
# ------------------------
. $KRN_EXE/_libkernel.sh
InitVariable WORKSPACE dir "Workspace directory for package building and storage"

# ---------------------
# Parsing des commandes
# ---------------------
Parametre=""
Commande=$(echo $1|tr [:upper:] [:lower:])
[ $# -gt 1 ] && Parametre="$(echo $*|cut -f2- -d' ')"

case $Commande in

    # Commandes pour le referentiel
    # -----------------------------
    "list"      |"ls") RunCommand ListKernel.sh   ;;
    "get"       |"gk") RunCommand GetKernel.sh    ;;
    "install"        ) RunCommand InstallKernel.sh;;
    "remove"         ) RunCommand RemoveKernel.sh ;;
    
    "changelog"    |"cl")  RunCommand ChangeLog.sh     ;;
    "getsource"    |"gs")  RunCommand GetSource.sh     ;;
    "genpackage"   |"gp")  RunCommand GenPackage.sh    ;;
    "compilinstall"|"cci") RunCommand CompilInstall.sh ;;

    *)
	echo "Kernel management : Commande 'krn $1' inconnue."
	Status=1
esac

exit $Status
