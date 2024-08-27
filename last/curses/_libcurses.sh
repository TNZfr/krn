#!/bin/bash

#-------------------------------------------------------------------------------
_InitCurses ()
{
    [ "$KRNC_TMP" != "" ] && return

    export KRNC_TMP=$KRN_TMP/curses-$$
    export KRNC_FIFO=$KRNC_TMP/fifo
    export KRNC_ErrorLog=$KRNC_TMP/ErrorLog
    export KRNC_BOARD=$KRNC_TMP/Board.csv

    mkdir -p $KRNC_TMP
    mkfifo   $KRNC_FIFO
    _CursesVar KRNC_debut=$(TopHorloge)
}

#-------------------------------------------------------------------------------
_CloseCurses ()
{
    [ "$KRNC_TMP" = "" ] && return
    rm -rf $KRNC_TMP
}

#-------------------------------------------------------------------------------
_CursesVar ()
{
    [ "$KRNC_TMP" = "" ] && return
    for _var in $*
    do
	if [ "${_var:0:9}" != "KRNC_PID=" ] \
	       || [ "$(grep ^KRNC_PID $KRNC_VAR)" = "" ]
	then
	    echo $_var >> $KRNC_FIFO &
	fi
    done
}

#-------------------------------------------------------------------------------
_CursesStep ()
{
    [ "$KRNC_TMP" = "" ] && return
    
    _CursesVar KRNC_$2_$1=$(TopHorloge)
    echo -e "Step-$2;$(echo $*|cut -d' ' -f3-)" > $KRNC_FIFO &
}

#-------------------------------------------------------------------------------
_InitBoard ()
{
    _Bdd=$1
    _Board=$2
    _Parameter=$(echo $*|cut -d' ' -f4-)

    _Generator=$(grep "^${_Board},generator," $_Bdd)
    if [ "$_Generator" = "" ]
    then   
	grep "^${_Board}," $_Bdd|grep -v "^${_Board},generator," > $KRNC_BOARD
	return
    fi

    _GenScript=$(echo $_Generator|cut -d',' -f5)
    $KRN_EXE/curses/$_GenScript $_Parameter
}

#-------------------------------------------------------------------------------
_Board_Init ()
{
    > $KRNC_BOARD
    Board=$(basename $1|cut -d. -f1|cut -d_ -f2)
}

#-------------------------------------------------------------------------------
_Board_Write ()
{
    echo "$Board,$Type,$Col,$Row,$P1,$P2," >> $KRNC_BOARD
}
