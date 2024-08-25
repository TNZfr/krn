#!/bin/bash

. $KRN_EXE/lib/kernel.sh

#-------------------------------------------------------------------------------
# Main

echo   ""
echo   "Syntax : ${KRN_Help_Prefix}SetConfig [ConfigFile|DEFAULT]"
echo   ""
echo   "  ConfigFile : Config file used for kernel compilation"
echo   ""
echo   "  DEFAULT"
echo   "    DEBIAN mode : /boot/config-$(uname -r)"
echo   "    REDHAT mode : /boot/config-$(uname -r)"
echo   "    ARCH* mode  : /proc/config.gz"
echo   ""

case $# in
    0)
	if [ -L $HOME/.krn/CompilConfig ]
	then
	    printf "Config file set : \033[32m$(readlink -f $HOME/.krn/CompilConfig)\033[m\n"
	else
	    echo "Default config file used."
	fi
    ;;

    1)
	if [ "$(echo $1|tr [:upper:] [:lower:])" = "default" ]
	then
	    rm -f $HOME/.krn/CompilConfig
	    echo "Default config file now used."
	else
	    ConfigFile=$(readlink -f $1)
	    [ -f $1 ] && ln -sf $ConfigFile $HOME/.krn/CompilConfig
	    printf "Config file now set : \033[32m$(readlink -f $HOME/.krn/CompilConfig)\033[m\n"
	fi
	;;

    *)
esac
echo ""

exit 0
