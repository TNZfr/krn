#!/bin/bash

. $KRN_EXE/lib/kernel.sh

#-------------------------------------------------------------------------------
# Main

if [ $# -lt 1 ]
then
    echo ""
    echo "Syntax : ${KRN_Help_Prefix}Watch KrnCommand Parameters"
    echo ""
    echo "  KrnCommand : krn command"
    echo "  Parameters : standard parameters for the concerned KrnCommand"
    echo ""
    exit 1
fi

KRN_Command="Watch-Refresh.sh Main.sh $*"

_MainCommand=$(echo $*|cut -d' ' -f1|tr [:upper:] [:lower:])
case $_MainCommand in
    "search"      |"se") _NewCommand="Search $(      echo $*|cut -d' ' -f2-)";;
    "verifykernel"|"vk") _NewCommand="VerifyKernel $(echo $*|cut -d' ' -f2-)";;

    "list"        |"ls")
	KRN_Command="Watch-Refresh.sh Main.sh List"
	_NewCommand="List"
	;;

    "setconfig"   |"sc") 
	KRN_Command="Watch-Refresh.sh Main.sh SetConfig"
	_NewCommand="SetConfig"
	;;

    *)
	echo ""
	echo "KRN command : $*"
	echo "This command is not expected to be watched every 10 seconds."
	echo "Allowed KRN Watch commands are : "
	echo " - ${KRN_Help_Prefix}Watch List"
	echo " - ${KRN_Help_Prefix}Watch Search ..."
	echo " - ${KRN_Help_Prefix}Watch VerifyKernel ..."
	echo " - ${KRN_Help_Prefix}Watch SetConfig"
	echo ""
	exit 0
esac

KRN_Title="Kernel Management / Watch 5s : $_NewCommand"

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
    echo "Watch on KRN Command can't be performed."
    echo ""
fi
exit 0
