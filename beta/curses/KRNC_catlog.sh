#!/bin/bash
echo "----------------------------------------------------------------------"
if [ ! -f $KRNC_ErrorLog ]
then
    tail -20 $KRNC_TMP/exec.log
else
    cat $KRNC_ErrorLog
fi
