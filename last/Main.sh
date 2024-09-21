#!/bin/bash

KRN_VERSION=v10.4

#-------------------------------------------------------------------------------
function RunCommand
{
    RunCommand_Name=$*
    AcctFile_Command=$(for Name in $*; do echo ${Name%.sh};done)
    AcctFile_Command=$(echo $AcctFile_Command|sed 's/ //g')

    # --------------------------------
    # Gestion de la LOG de la commande
    # --------------------------------
    KRN_FICACC="/dev/null"
    if [ -n "$KRN_ACCOUNTING" ] && [ -d $KRN_ACCOUNTING ]
    then
	KRN_FICACC=$KRN_ACCOUNTING/$(date +%Y%m%d-%Hh%Mm%Ss)-$AcctFile_Command.log
	printf "\n\033[33;44m Command \033[m : krn $Command $Parameter\n" > $KRN_FICACC
	chmod a+rw $KRN_FICACC
    fi

    if [ $KRN_FICACC = "/dev/null" ]
    then
	${RunCommand_Name} $Parameter
	Status=$?
    else
	StatusFile=$KRN_TMP/status-$$
	(${RunCommand_Name} $Parameter;echo $? > $StatusFile) | tee -a $KRN_FICACC
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
    echo   " - DEBIAN mode      : Debian based distributions (Debian, *Ubuntu, KDE Neon ...)"
    echo   " - REDHAT mode      : Redhat based distributions (RHEL, AlmaLinux, Fedora ...)"
    echo   " - ARCH mode        : Arch-Linux distribution (linux-upstream)"
    echo   " - ARCH-CUSTOM mode : Arch-Linux distribution (linux-x.y.z[-rc?])"
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
    echo  "Curses         (CU): Display step list of KRN command giving information and elapsed time."
    echo  ""
    printf "\033[34m Workspace management \033[m\n"
    printf "\033[34m----------------------\033[m\n"
    echo  "Configure      (CF): Display parameters. To reset, run krn configure RESET"
    echo  "List           (LS): List current kernel, installed kernel and available kernels from local"
    echo  "Purge              : Remove packages and kernel build directories from workspace"
    echo  ""
    printf "\033[34m Kernel from Local or Ubuntu/Mainline \033[m\n"
    printf "\033[34m--------------------------------------\033[m\n"
    echo  "Search         (SE): Search available kernels from Kernel.org (including Ubuntu/Mainline in DEBIAN mode)"
    echo  ""
    echo  "Get                : Get Debian packages from local (including Ubuntu/Mainline in DEBIAN mode)"
    echo  "Install            : Install selected kernel from local (including Ubuntu/Mainline in DEBIAN mode)"
    echo  "Remove             : Remove selected installed kernel"
    echo  ""
    echo  "CreateSign         : Create signature certificate and enroll in UEFI/SecureBoot (or not)"
    echo  "Sign           (SK): Sign installed kernel"
    echo  "SignModule     (SM): Sign module file(s)"
    echo  "VerifyKernel   (VK): Verify installed kernel and module signatures"
    echo  "InstallSign    (IS): Install and sign selected kernel"
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
    echo  "CompileSign         (CCS): Compile and sign kernel"
    echo  "CompileSignInstall (CCSI): Get sources, compile, sign and install kernel"
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
    echo "Update       (UPD): Update cache of available versions (cdn, git ...)"
    echo "Upgrade      (UPG): Upgrade kernels set installed on the system"
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

# Environment variables init
# --------------------------
. $KRN_EXE/Configure.sh LOAD
export KRN_MODE=$(        echo $KRN_MODE        |tr [:lower:] [:upper:])
export KRN_ARCHITECTURE=$(echo $KRN_ARCHITECTURE|tr [:upper:] [:lower:])
export KRN_LIB=$KRN_EXE/lib/$KRN_MODE

[ "$KRN_CLI" = "" ]              && export KRN_Help_Prefix="krn " || export KRN_Help_Prefix=""
[ $LOGNAME = root ]              && export KRN_sudo=""            || export KRN_sudo="sudo"
[ $(_GetDevShmFreeMB) -gt 1024 ] && export KRN_TMP=/dev/shm       || export KRN_TMP=/tmp

# Blocking olf beta KRN_MODE
# --------------------------
if [ $KRN_MODE = GENTOO ]
then
    echo ""
    echo "GENTOO mode is more supported."
    echo "Please use previous version (krn9.2) for beta testing"
    echo ""
    exit 1
fi

# Coammnds parsing
# ----------------
Parameter=""
Command=$(echo $1|tr [:upper:] [:lower:])
[ $# -gt 1 ] && Parameter="$(echo $*|cut -f2- -d' ')"

case $Command in

    "help"              |"h" )    Help                       ;;
    "cli"                    )    DirectCommand              ;;
    "curses"            |"cu")    Curses.sh $Parameter       ;;
    "detach"            |"dt")    Detach.sh $Parameter       ;;
    "watch"             |"wa")    Watch.sh  $Parameter       ;;

    "configure"         |"cf")    RunCommand Configure.sh    ;;
    "purge"                  )    RunCommand Purge.sh        ;;
    "list"              |"ls")    RunCommand List.sh         ;;
    "search"            |"se")    RunCommand Search.sh       ;;
    "get"               |"gk")    RunCommand GetKernel.sh    ;;
    "install"                )    RunCommand Install.sh      ;;
    "remove"                 )    RunCommand Remove.sh       ;;
    
    "createsign"             )    RunCommand CreateSign.sh   ;;
    "sign"              |"sk")    RunCommand Sign.sh         ;;
    "signmodule"        |"sm")    RunCommand SignModule.sh   ;;
    "installsign"       |"is")    RunCommand InstallSign.sh  ;;
    "verifykernel"      |"vk")    RunCommand VerifyKernel.sh ;;
    
    "changelog"         |"cl")    RunCommand ChangeLog.sh    ;;
    "getsource"         |"gs")    RunCommand GetSource.sh    ;;

    "compile"           |"cc")    RunCommand Compile.sh            ;;
    "compileinstall"    |"cci")   RunCommand CompileInstall.sh     ;;
    "compilesign"       |"ccs")   RunCommand CompileSign.sh        ;;
    "compilesigninstall"|"ccsi")  RunCommand CompileSignInstall.sh ;;

    "setconfig"         |"sc")    RunCommand SetConfig.sh        ;;
    "kernelconfig"      |"kc")    RunCommand KernelConfig.sh     ;;
    "confcomp"          |"kcc")   RunCommand ConfComp.sh         ;;
    "confcompinstall"   |"kcci")  RunCommand ConfCompInstall.sh  ;;
    "confcompsign"      |"kccs")  RunCommand ConfCompSign.sh     ;;
    "confcompsigninst"  |"kccsi") RunCommand ConfCompSignInst.sh ;;
    
    "savelog"           |"sl")    SaveLog.sh ;;

    # Advanced usages
    "update"    |"upd") RunCommand Update.sh     ;;
    "upgrade"   |"upg") RunCommand Upgrade.sh    ;;
    "autoremove"|"ar")  RunCommand AutoRemove.sh ;;
    "autoclean" |"ac")  RunCommand AutoClean.sh  ;;

    # Internal commands
    "_updatecompletion") _RefreshWorkspaceList    ;;
    "_getvar")           eval echo \$${Parameter} ;;
    
    *)
	echo "Kernel management : 'krn $1' unknown command."
	Status=1
esac

exit $Status
