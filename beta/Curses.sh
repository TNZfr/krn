#!/bin/bash

. $KRN_EXE/_libkernel.sh

#-------------------------------------------------------------------------------
# Main

if [ $# -lt 1 ]
then
    echo ""
    echo "Syntax : ${KRN_Help_Prefix}Curses KrnCommand Parameters"
    echo ""
    echo "  KrnCommand : krn command"
    echo "  Parameters : standard parameters for the concerned KrnCommand"
    echo ""
    exit 1
fi

KRN_Title="Kernel Management Board : $*"
KRN_Command="Curses-Exec.sh $*"

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
    echo ""
    echo "No graphic terminal software found."
    echo ""
fi

exit 0
