#!/bin/bash

. $KRN_EXE/_libkernel.sh

#-------------------------------------------------------------------------------
# Main
#

_RefreshInstalledKernel
ModuleList=$KRN_RCDIR/.ModuleList

NbKernel=$(cat $ModuleList|wc -l)
if [ $NbKernel -lt 3 ]
then
    echo ""
    echo "Kernel install already clean."
    echo ""
    exit 0
fi

(( NbToRemove = NbKernel - 2 ))
Remove_${KRN_MODE}.sh $(cat $ModuleList|linux-version-sort|head -$NbToRemove |cut -d',' -f2)

exit 0
