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
    # cursor OFF, cursor home, erase full screen, refresh date time
    echo -e "\033[25l\033[H\033[2J\033[37;44m *** $(date +'%Y/%m/%d - %Hh %Mm %Ss') *** \033[m\n" > $WATCH_TMP

    # exec command
    $* >> $WATCH_TMP 2>&1

    # cursor ON
    echo -e "\033[25h" >> $WATCH_TMP

    # Refresh screen
    cat $WATCH_TMP
    sleep 5
done

exit 0
