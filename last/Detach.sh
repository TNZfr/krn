#!/bin/bash

. $KRN_EXE/_libkernel.sh

#-------------------------------------------------------------------------------
# Main

if [ $# -lt 1 ]
then
    echo ""
    echo "Syntax : [krn] Detach KrnCommand Parameters"
    echo ""
    echo "  KrnCommand : krn command"
    echo "  Parameters : standard parameters for the concerned KrnCommand"
    echo ""
    exit 1
fi

KRN_Title="Kernel Management : $*"
KRN_Command="Detach-Exec.sh Main.sh $*"

#-------------------------------------------------------------------------------
# KDE Plasma Konsole
# ------------------
if   [ "$(which konsole)" != "" ]
then
    konsole                       \
	-ptabtitle="$KRN_Title"   \
	-e bash -c "$KRN_Command" 2>/dev/null &
#-------------------------------------------------------------------------------
# Gnome-terminal
# --------------
elif [ "$(which gnome-terminal)" != "" ]
then
    gnome-terminal                \
	--hide-menubar            \
	--title "$KRN_Title"      \
	-- bash -c "$KRN_Command"
    
#-------------------------------------------------------------------------------
# Other Desktop Environment (xterm)
# -------------------------
elif [ "$(which xterm)" != "" ]
then
    xterm                   \
	-title "$KRN_Title" \
	-e "$KRN_Command"   &
    
#-------------------------------------------------------------------------------
# No Desktop Environment
# ----------------------
else
    KRN_LOG=$(date +%Y%m%d-%Hh%Mm%Ss)-KRN-$(echo $*|cut -d' ' -f1|tr [:lower:] [:upper:]).log
    
    echo ""
    echo "No graphic terminal software found."
    echo "Command output saved in : $KRN_LOG"
    echo ""
    echo "Following possible with command :"
    echo "tail -f $KRN_LOG"
    echo ""

    Main.sh $* > $KRN_LOG 2>&1 &
fi

exit 0
