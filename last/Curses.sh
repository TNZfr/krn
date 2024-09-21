#!/bin/bash

. $KRN_EXE/lib/kernel.sh
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
export KRNC_BDD=$KRN_EXE/curses/boards.csv
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
NeedSudo=FALSE
case $(echo $_MainCommand|tr [:upper:] [:lower:]) in

    "getsource"         |"gs")    _CursesBoard=GetSource          ;;

    "compile"           |"cc" )   _CursesBoard=Compile            ;;
    "compileinstall"    |"cci")   _CursesBoard=CompileInstall     ; NeedSudo=TRUE ;;
    "compilesign"       |"ccs")   _CursesBoard=CompileSign        ;;
    "compilesigninstall"|"ccsi")  _CursesBoard=CompileSignInstall ; NeedSudo=TRUE ;;
    
    "confcomp"          |"kcc")   _CursesBoard=ConfComp           ;;
    "confcompinstall"   |"kcci")  _CursesBoard=ConfCompInstall    ; NeedSudo=TRUE ;;
    "confcompsign"      |"kccs")  _CursesBoard=ConfCompSign       ;;
    "confcompsigninst"  |"kccsi") _CursesBoard=ConfCompSignInst   ; NeedSudo=TRUE ;;

    "install"                )    _CursesBoard=Install            ; NeedSudo=TRUE ;;
    "remove"                 )    _CursesBoard=Remove             ; NeedSudo=TRUE ;;
    "sign"              |"sk")    _CursesBoard=Sign               ; NeedSudo=TRUE ;;
    "signmodule"        |"sm")    _CursesBoard=SignModule         ; NeedSudo=TRUE ;;
    "installsign"       |"is")    _CursesBoard=InstallSign        ; NeedSudo=TRUE ;;

    *)
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
	echo ""
    exit 0
esac

# -------------------------------------
# Signing kernel thru board
# is not possible (interactive capture)
# -------------------------------------
if [  $_CursesBoard != SignModule ] && \
       [ "$KRNSB_PASS" != "" ]      && \
       [ "$(echo $_CursesBoard|grep Sign)" != "" ]
then
    echo ""
    echo "Signing kernel thru board using a password"
    echo "is not possible (interactive capture)."
    echo ""
    exit 0
fi

# Install and sudo management
# ---------------------------
if [ $NeedSudo = TRUE ]
then
    echo ""
	echo "Administrator rights needed"
	sudo clear
fi

# Run board
# ---------
_InitCurses
_InitBoard  $KRNC_BDD $_CursesBoard $_KrnParameter

(
    echo "" > $KRNC_TMP/exec.log
    $KRN_EXE/Main.sh $_KrnParameter >> $KRNC_TMP/exec.log 2>&1
    _CursesVar KRNC_fin=$(TopHorloge)
) &

export KRNC_RefreshTimer=1

$KRN_EXE/curses/KRNC_Timer $KRNC_FIFO  $KRNC_RefreshTimer 2>/dev/null &
$KRN_EXE/curses/KRN_Curses $KRNC_BOARD
_CloseCurses

echo   ""
exit 0
