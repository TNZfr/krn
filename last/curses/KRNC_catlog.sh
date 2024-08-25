#!/bin/bash

Row=$1
Col=$2
Refresh=$3

(( Row += 22 ))

echo -e "----------------------------------------------------------------------"
echo -e "\033[36m$(date +"%d/%m/%Y %Hh%Mm%Ss")\033[m  "

# Force refresh 
[ "$Refresh" != "" ] && rm -f $KRNC_TMP/RefreshLog

# Refresh only if $KRNC_TMP/exec.log changed
if [ -f $KRNC_TMP/RefreshLog ] && [ $KRNC_TMP/exec.log -ot $KRNC_TMP/RefreshLog ]
then
    echo -e "\033[${Row};${Col}H"
    exit
fi

# Refresh
touch $KRNC_TMP/RefreshLog

echo -e "\033[0J"
if [ ! -f $KRNC_ErrorLog ]
then
    tail -20 $KRNC_TMP/exec.log
    echo -e "\033[${Row};${Col}H"
else
    cat $KRNC_ErrorLog
fi
