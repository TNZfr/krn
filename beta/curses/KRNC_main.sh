#!/bin/bash

. $KRN_EXE/_libkernel.sh
. $KRN_EXE/curses/_libcurses.sh
. $KRN_EXE/curses/simple_curses.sh

#-------------------------------------------------------------------------------
# Curses
main ()
{
    # loading metrics
    _GetVar
    
    if [ -d /proc/$KRNC_PID ]
    then
	_status=$(echo -ne "\033[5;32mRUNNING\033[m since $(_GetDuration $KRNC_debut)")
    else
	[ "$KRNC_fin" = "" ] && KRNC_fin=$(TopHorloge)
	_status="Terminated, \033[22melapsed $(_GetDuration $KRNC_debut $KRNC_fin)\033[m"
    fi

    # Display board
    . $KRNC_TMP/Board.sh 

    addsep
    if [ ! -f $KRNC_ErrorLog ]
    then
	tail_file $KRNC_TMP/exec.log -20
    else
	append_file $KRNC_ErrorLog
    fi
    endwin
}

update ()
{
    [ "$KRNC_fin" != "" ] && return 255
    sleep 0.69
}

#-------------------------------------------------------------------------------
# Main
#
KRNC_Board=$1
KRNC_Parameter="$(echo $*|cut -d' ' -f3-)"

# Generation des commandes BSC
ScriptGenerator=$KRN_EXE/curses/$(grep "^${KRNC_Board},BoardGenerator,," $KRNC_BDD|cut -d',' -f4)
$ScriptGenerator $*

# Creation script tempo contenant les append_tabbed
# source du script tempo
KRNC_debut=$(TopHorloge)
main_loop
