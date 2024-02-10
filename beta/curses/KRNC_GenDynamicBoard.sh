#!/bin/bash

#-------------------------------------------------------------------------------
# Main
#
KRNC_Board=$1
KRNC_Parameter="$(echo $*|cut -d' ' -f3-)"

# Generation des commandes BSC
> $KRNC_TMP/Board.sh

# Entete 
Title=$(grep "^${KRNC_Board},window," $KRNC_BDD|cut -d',' -f4)
echo "window \"$Title : \$_status\"" >> $KRNC_TMP/Board.sh

Index=1
for Param in $KRNC_Parameter
do
    grep "^${KRNC_Board}," $KRNC_BDD | \
	grep -v -e ",BoardGenerator," -e ",window," | \
	while read _record
	do
	    Command=$( echo $_record|cut -d',' -f2)
	    IndexFmt=$(echo $_record|cut -d',' -f3)
	    Title=$(   echo $_record|cut -d',' -f4)
	    
	    StepFmt=$( echo $_record|cut -d',' -f5)
	    Step=$(printf "$StepFmt" $Index)
	   
	    echo "$Command \"$(printf "$IndexFmt" $Index) - ${Title} $Param:\$(_GetStep ${Step}):\$(_GetDuration \$KRNC_${Step}_debut \$KRNC_${Step}_fin)\" 3" >> $KRNC_TMP/Board.sh
	done
    (( Index += 1 ))
done
