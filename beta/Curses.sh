#!/bin/bash

. $KRN_EXE/_libkernel.sh
. $KRN_EXE/curses/_libcurses.sh

#-------------------------------------------------------------------------------
# Main
#
# Script run by KRN Detach 
#
_MainCommand=$1
_KrnParameter=$*
export KRNC_Parameter=$(echo $*|cut -d' ' -f2-)

# Board Availability for current mode
# -----------------------------------
export KRNC_BDD=$KRN_EXE/curses/boards_${KRN_MODE}.csv
if [ ! -f $KRNC_BDD ]
then
    echo ""
    echo "No board database available for KRN mode $KRN_MODE"
    echo ""
    printf "Press a key to close ..."
    read -n1 dummy
    exit 0
fi

# Find KRNCurses boards
# ---------------------
case $(echo $_MainCommand|tr [:upper:] [:lower:]) in

    "getsource"         |"gs")    _CursesBoard=GetSource          ; NeedSudo=FALSE;;

    "compile"           |"cc" )   _CursesBoard=Compile            ; NeedSudo=FALSE;;
    "compileinstall"    |"cci")   _CursesBoard=CompileInstall     ; NeedSudo=TRUE ;;
    "compilesign"       |"ccs")   _CursesBoard=CompileSign        ; NeedSudo=FALSE;;
    "compilesigninstall"|"ccsi")  _CursesBoard=CompileSignInstall ; NeedSudo=TRUE ;;
    
    "confcomp"          |"kcc")   _CursesBoard=ConfComp           ; NeedSudo=FALSE;;
    "confcompinstall"   |"kcci")  _CursesBoard=ConfCompInstall    ; NeedSudo=TRUE ;;
    "confcompsign"      |"kccs")  _CursesBoard=ConfCompSign       ; NeedSudo=FALSE;;
    "confcompsigninst"  |"kccsi") _CursesBoard=ConfCompSignInst   ; NeedSudo=TRUE ;;

    "install"                )    _CursesBoard=Install            ; NeedSudo=TRUE ;;
    "remove"                 )    _CursesBoard=Remove             ; NeedSudo=TRUE ;;
    "sign"              |"sk")    _CursesBoard=Sign               ; NeedSudo=TRUE ;;
    "installsign"       |"is")    _CursesBoard=InstallSign        ; NeedSudo=TRUE ;;

    *)
	_CursesBoard=None
esac

if [ $_CursesBoard != None ]
then
    # Install and sudo management
    if [ $NeedSudo = TRUE ]
    then
	echo ""
	echo "Administrator rights needed"
	sudo clear
    fi
    
    _InitCurses
    _InitBoard  $KRNC_BDD $_CursesBoard $_KrnParameter
    ($KRN_EXE/Main.sh $_KrnParameter > $KRNC_TMP/exec.log 2>&1; _CursesVar KRNC_fin=$(TopHorloge))&
    $KRN_EXE/curses/KRN_Curses $KRNC_BOARD
    _CloseCurses
else
    if [ "$_MainCommand" != "" ]
    then
	echo ""
	echo "No curses board found for $_MainCommand."
    fi
    echo ""
    echo "Available KRN command boards :"
    for Board in $(cat $KRNC_BDD|cut -d',' -f1|grep -v "Board Name"|sort|uniq)
    do
	Board=$(echo $Board|tr ['_'] [' '])
	[ "$Board" = "main" ] && continue
	echo "- $Board"
    done
fi

echo   ""
exit 0
