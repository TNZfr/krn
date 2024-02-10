#!/bin/bash

#-------------------------------------------------------------------------------
# Main
#
KRNC_Board=$1
KRNC_Parameter="$(echo $*|cut -d' ' -f3-)"

# Generation des commandes BSC
> $KRNC_TMP/Board.sh 
grep "^${KRNC_Board}," $KRNC_BDD | \
    grep -v ",BoardGenerator,"   | \
    cut -d',' -f2-               | \
    while read _record
    do
	# Format : 1.BSC command, 2.Index, 3.Title, 4.Step
	Command=$(echo $_record|cut -d',' -f1)
	Title=$(  echo $_record|cut -d',' -f3)
	
	case $Command in
	    window)
		echo "$Command \"$Title : \$_status\"" >> $KRNC_TMP/Board.sh
		;;

	    append_tabbed)
		Index=$(echo $_record|cut -d',' -f2)
		Step=$( echo $_record|cut -d',' -f4)
		
		Index="$(printf "%2d" $Index)"
		echo "$Command \"$(printf "%02d" $Index) - ${Title}:\$(_GetStep ${Step}):\$(_GetDuration \$KRNC_${Step}_debut \$KRNC_${Step}_fin)\" 3" >> $KRNC_TMP/Board.sh
		;;
	esac
    done
