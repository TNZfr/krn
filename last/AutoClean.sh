#!/bin/bash

. $KRN_EXE/lib/kernel.sh

#-------------------------------------------------------------------------------
# Main
#

_RefreshWorkspaceList
WorkspaceList=$KRN_WORKSPACE/.CompletionList

NbItem=$(grep -v ",cfg," $WorkspaceList|wc -l)
if [ $NbItem -eq 0 ]
then
    echo ""
    echo "Workspace already clean."
    echo ""
    exit 0
fi

ckc_list=$(  grep    ",ckc," $WorkspaceList                |cut -d',' -f4)
other_list=$(grep -v ",ckc," $WorkspaceList|grep -v ",cfg,"|cut -d',' -f1)

Purge.sh $ckc_list $other_list

exit 0
