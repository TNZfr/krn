#!/bin/bash

#-------------------------------------------------------------------------------
_InitCurses ()
{
    [ "$KRNC_TMP" != "" ] && return

    export KRNC_TMP=$KRN_TMP/curses-$$
    mkdir -p $KRNC_TMP
    export KRNC_VAR=$KRNC_TMP/var
    export KRNC_ErrorLog=$KRNC_TMP/ErrorLog
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
    for _var in $*; do echo $_var >> $KRNC_VAR; done
}

#-------------------------------------------------------------------------------
_GetVar ()
{
    [ -f $KRNC_VAR ] && . $KRNC_VAR
}

#-------------------------------------------------------------------------------
_CursesStep ()
{
    [ "$KRNC_TMP" = "" ] && return
    
    _CursesVar KRNC_$2_$1=$(TopHorloge)
    echo -e "$(echo $*|cut -d' ' -f3-)" > $KRNC_TMP/Step-$2
}

#-------------------------------------------------------------------------------
_GetStep ()
{
    [ ! -f $KRNC_TMP/Step-$1 ] && echo "" && return
    cat $KRNC_TMP/Step-$1
}

#-------------------------------------------------------------------------------
_GetDuration ()
{
    _debut=$1
    _fin=$2

    [ "$_debut" = "" ] && echo "" && return

    if [ "$_fin" != "" ]
    then
	echo -ne "\033[22;34m$(AfficheDuree $_debut $_fin)\033[m"
    else
	AfficheDuree $_debut $(TopHorloge)
    fi
}
