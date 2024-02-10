#!/bin/bash

#-------------------------------------------------------------------------------
# Main
#
# Script run by KRN Detach to provide refresh option
#

# Cleaning previous tmp directories
# ---------------------------------
[ -f $KRN_TMP/krn-watch-* ] && for WATCH_TMP in $KRN_TMP/krn-watch-*
do
    WATCH_PID=$(basename $WATCH_TMP|cut -d- -f3)
    [ ! -d /proc/$WATCH_PID ] && rm -rf $WATCH_TMP
done

# Temp directory
WATCH_TMP=$KRN_TMP/krn-watch-$$

# Main loop
while [ -d /tmp ]
do
    $* > $WATCH_TMP 2>&1
    clear
    printf "\033[37;44m *** $(date +'%Y %m %d - %Hh %Mm %Ss') *** \033[m\n"
    cat   $WATCH_TMP
    rm -f $WATCH_TMP
    sleep 10
done

exit 0
