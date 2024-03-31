#!/bin/bash

KRN_VERSION=v9.1-rc3

#-------------------------------------------------------------------------------
function RunCommand
{
    RunCommand_Name=$*
    AcctFile_Commande=$(for Name in $*; do echo ${Name%.sh};done)
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
	StatusFile=$KRN_TMP/status-$$
	(${RunCommand_Name} $Parametre;echo $? > $StatusFile) | tee -a $KRN_FICACC
	Status=$(cat $StatusFile; rm -f $StatusFile)
    fi

    return $Status
}

#-------------------------------------------------------------------------------
function Help
{
    echo   ""
    printf " \033[30;42m KRN $KRN_VERSION \033[m : Kernel management tool\n"
    echo   ""
    echo   " - Mode DEBIAN      : Debian based distributions (Debian, *Ubuntu, KDE Neon ...)"
    echo   " - Mode REDHAT      : Redhat based distributions (RHEL, Centos, Fedora ...)"
    echo   " - Mode ARCH        : Arch-Linux distribution with kernel named version"
    echo   " - Mode ARCH-CUSTOM : Arch-Linux distribution with fixed kernel name"
    echo   " - Mode GENTOO      : Gentoo distribution"
    echo   ""
    printf "\033[34m Bash auto completion \033[m\n"
    printf "\033[34m----------------------\033[m\n"
    echo   "run command : krn Configure"
    echo   ""
    printf "\033[37;44m Syntax \033[m : ${KRN_Help_Prefix}Command Parameters ...\n"
    echo  ""
    printf "\033[34m Tool management \033[m\n"
    printf "\033[34m-----------------\033[m\n"
    echo  "Help            (H): Display main help page"
    echo  "CLI                : Launch KRN command interpreter."
    echo  "Detach         (DT): Detach KRN command in an other terminal or in a log file."
    echo  "Watch          (WA): Detach KRN command in an other terminal refreshed every 5 seconds."
    echo  ""
    printf "\033[34m Workspace management \033[m\n"
    printf "\033[34m----------------------\033[m\n"
    echo  "Configure      (CF): Display parameters. To reset, run krn configure RESET"
    echo  "List           (LS): List current kernel, installed kernel and available kernels from local"
    echo  "Purge              : Remove packages and kernel build directories from workspace"
    echo  ""
    printf "\033[34m Kernel from Local or Ubuntu/Mainline \033[m\n"
    printf "\033[34m--------------------------------------\033[m\n"
    echo  "Search         (SE): Search available kernels from Kernel.org (and Ubuntu/Mainline in DEBIAN mode)"
    echo  ""
    echo  "Get                : Get Debian packages from local (and Ubuntu/Mainline in DEBIAN mode)"
    echo  "Install            : Install selected kernel from local (and Ubuntu/Mainline in DEBIAN mode)"
    echo  "Remove             : Remove selected installed kernel"
    echo  ""
    echo  "CreateSign         : Create signature certificate and enroll in UEFI/SecureBoot (or not)"
    echo  "Sign           (SK): Sign installed kernel (DEBIAN stable, beta for other mode)"
    echo  "VerifyKernel   (VK): Verify installed kernel and module signatures"
    echo  "InstallSign    (IS): Install and sign selected kernel (DEBIAN stable, beta for other mode)"
    echo  ""
    printf "\033[34m Sources from kernel.org \033[m\n"
    printf "\033[34m-------------------------\033[m\n"
    echo  "ChangeLog            (CL): Get Linux changelog file from kernel.org and display selection"
    echo  "GetSource            (GS): Get Linux sources archive from kernel.org"
    echo  ""
    printf "\033[32mStandard compilation\033[m\n"
    echo  "SetConfig            (SC): Display and set default config file for kernel compilation"
    echo  "Compile              (CC): Get sources and compile kernel"
    echo  "CompileInstall      (CCI): Get sources, compile and install kernel"
    echo  "CompileSign         (CCS): Compile and sign kernel (DEBIAN, beta for ARCH and GENTOO)"
    echo  "CompileSignInstall (CCSI): Get sources, compile, sign and install kernel (DEBIAN stable, beta for other mode)"
    echo  ""
    printf "\033[32mCustom compilation \033[m\n"
    echo  "KernelConfig         (KC): Generate a custom kernel config file (Can be used with krn SetConfig)"
    echo  "ConfComp            (KCC): Configure kernel and compile"
    echo  "ConfCompInstall    (KCCI): Configure kernel, compile and install"
    echo  "ConfCompSign       (KCCS): Configure kernel and compile signed kernel/modules"
    echo  "ConfCompSignInst  (KCCSI): Configure kernel, compile signed kernel/modules and install"
    echo  ""
    printf "\033[34m Log management \033[m\n"
    printf "\033[34m----------------\033[m\n"
    echo "SaveLog (SL)      : Save logs in directory defined by KRN_ACCOUNTING"
    echo ""
    printf "\033[34m Advanced usage \033[m\n"
    printf "\033[34m----------------\033[m\n"
    echo "Update            : Update cache of available versions (cdn, git ...)"
    echo "Upgrade           : Upgrade kernels set installed on the system"
    echo "AutoRemove    (AR): Auto remove old kernels and keep the 2 last versions"
    echo "AutoClean     (AC): Auto purge old kernels in then workspace directory"
    echo ""
}

#-------------------------------------------------------------------------------
function DirectCommand
{
    export KRN_CLI=TRUE
    
    echo   ""
    printf " \033[30;42m KRN $KRN_VERSION \033[m : Kernel management tool\n"
    echo   ""
    echo   "Commands summary : "
    echo   "  - Help for main manual page."
    echo   "  - Exit or Ctrl^D"
    echo   ""
    cli_status=0
    while [ $cli_status -eq 0 ]
    do
	Command_Parameters=""
	printf "Krn/\033[34m$(uname -r)\033[m > "
	read Command_Parameters
	cli_status=$?
	
	case $(echo "$Command_Parameters"|tr [:upper:] [:lower:]) in
	    "")
		# Rien a faire
	    ;;
	    
	    "exit" )
		cli_status=1
		;;
	    *)
		Main.sh $Command_Parameters
	esac
    done
    echo ""
}

#-------------------------------------------------------------------------------
# main
#

# Definition du repertoire des binaires
# -------------------------------------
export KRN_EXE=$(dirname $(readlink -f $0))
export PATH=$KRN_EXE:$PATH

if [ $# -eq 0 ]
then
    echo   ""
    printf " \033[30;42m KRN $KRN_VERSION \033[m : Kernel management tool\n"
    echo   ""
    echo   "Commands summary : "
    echo   "  - krn Help for main manual page."
    echo   "  - krn CLI for command interpreter."
    echo   ""
    exit 0
fi

# Chargement des variables
# ------------------------
. $KRN_EXE/Configure.sh LOAD
export KRN_MODE=$(        echo $KRN_MODE        |tr [:lower:] [:upper:])
export KRN_ARCHITECTURE=$(echo $KRN_ARCHITECTURE|tr [:upper:] [:lower:])

[ "$KRN_CLI" = "" ] && export KRN_Help_Prefix="krn " || export KRN_Help_Prefix=""
[ $LOGNAME = root ] && export KRN_sudo=""            || export KRN_sudo="sudo"

export KRN_TMP=/tmp
KRN_DEVSHM=$(echo $(df -m /dev/shm|grep /dev/shm)|cut -d' ' -f4);
[ "$KRN_DEVSHM" = "" ] && KRN_DEVSHM=0
[ $KRN_DEVSHM -gt 1024 ] && export KRN_TMP=/dev/shm 

# ---------------------
# Parsing des commandes
# ---------------------
Parametre=""
Commande=$(echo $1|tr [:upper:] [:lower:])
[ $# -gt 1 ] && Parametre="$(echo $*|cut -f2- -d' ')"

case $Commande in

    "help"              |"h" )    Help                              ;;
    "cli"                    )    DirectCommand                     ;;
    "curses"            |"cu")    Curses.sh $Parametre              ;;
    "detach"            |"dt")    Detach.sh $Parametre              ;;
    "watch"             |"wa")    Watch.sh  $Parametre              ;;

    "configure"         |"cf")    RunCommand Configure.sh           ;;
    "purge"                  )    RunCommand Purge.sh               ;;
    "list"              |"ls")    RunCommand List.sh                ;;
    "search"            |"se")    RunCommand Search.sh              ;;
    "get"               |"gk")    RunCommand GetKernel.sh           ;;
    "install"                )    RunCommand Install_${KRN_MODE}.sh ;;
    "remove"                 )    RunCommand Remove_${KRN_MODE}.sh  ;;
    
    "createsign"             )    RunCommand CreateSign.sh              ;;
    "sign"              |"sk")    RunCommand Sign_${KRN_MODE}.sh        ;;
    "installsign"       |"is")    RunCommand InstallSign_${KRN_MODE}.sh ;;
    "verifykernel"      |"vk")    RunCommand VerifyKernel.sh            ;;
    
    "changelog"         |"cl")    RunCommand ChangeLog.sh ;;
    "getsource"         |"gs")    RunCommand GetSource.sh ;;

    "compile"           |"cc")    RunCommand Compile_${KRN_MODE}.sh            ;;
    "compileinstall"    |"cci")   RunCommand CompileInstall_${KRN_MODE}.sh     ;;
    "compilesign"       |"ccs")   RunCommand CompileSign_${KRN_MODE}.sh        ;;
    "compilesigninstall"|"ccsi")  RunCommand CompileSignInstall_${KRN_MODE}.sh ;;

    "setconfig"         |"sc")    RunCommand SetConfig.sh        ;;
    "kernelconfig"      |"kc")    RunCommand KernelConfig.sh     ;;
    "confcomp"          |"kcc")   RunCommand ConfComp.sh         ;;
    "confcompinstall"   |"kcci")  RunCommand ConfCompInstall.sh  ;;
    "confcompsign"      |"kccs")  RunCommand ConfCompSign.sh     ;;
    "confcompsigninst"  |"kccsi") RunCommand ConfCompSignInst.sh ;;
    
    "savelog"           |"sl")    SaveLog.sh ;;

    # Advanced usages
    "update"         ) RunCommand Update.sh     ;;
    "upgrade"        ) RunCommand Upgrade.sh    ;;
    "autoremove"|"ar") RunCommand AutoRemove.sh ;;
    "autoclean" |"ac") RunCommand AutoClean.sh  ;;

    # Internal commands
    "_updatecompletion") _RefreshWorkspaceList    ;;
    "_getvar")           eval echo \$${Parametre} ;;
    
    *)
	echo "Kernel management : 'krn $1' unknown command."
	Status=1
esac

exit $Status
