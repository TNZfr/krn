#!/bin/bash

. $KRN_EXE/lib/kernel.sh

#-------------------------------------------------------------------------------
# Main

if [ $# -lt 1 ]
then
    echo ""
    echo "Syntax : ${KRN_Help_Prefix}ChangeLog Version [Pattern] [...]"
    echo ""
    echo "  Version : as it appears in krn List output command"
    echo "            or just the version number"
    echo "  Pattern : to be displayed from commits labels"
    echo ""
    exit 1
fi

Debut=$(TopHorloge)

Version=$1
AllPattern="None"
if [ $# -gt 1 ]
then
    AllPattern=""
    for Pattern in $(echo $* |cut -d' ' -f2-); do AllPattern="$AllPattern -e $Pattern"; done
fi

Directory=v$(echo $Version|cut -d. -f1).x
URL=https://cdn.kernel.org/pub/linux/kernel/$Directory/ChangeLog-$Version
ChangeLog=$KRN_TMP/changelog-$$
wget -q --no-check-certificate $URL -O $ChangeLog 2>/dev/null

# Comptage des commits
NbCommit=$(grep ^commit $ChangeLog|wc -l)
((NbCommit -= 1))

echo   ""
printf "*** \033[34m$NbCommit commit(s)\033[m for kernel version $Version ***\n"
echo   ""

CL_libelle=$KRN_TMP/changelog-source-$$
grep -A4 ^commit $ChangeLog | \
    (while read Line; do [ "$Line" = "--" ] && echo $PrevLine; PrevLine=$Line; done; echo $PrevLine)| \
    grep -v "^Linux $Version" > $CL_libelle

if [ "$AllPattern" != "None" ]
then
    CL_Found=$KRN_TMP/changelog-found-$$
    > $CL_Found
    cat $CL_libelle | grep -ni $AllPattern | sort -n | \
	while read Line
	do
	    Number=$(echo $Line|cut -d':' -f1)
	    Label=$(echo $Line|cut -d':' -f2-)
	    printf "\033[32mCommit %6s\033[m : %s\n" "#$Number" "$Label"|tee -a $CL_Found
	done
    
    NbFound=$(cat $CL_Found|wc -l)
    rm -f $CL_Found

    Pourcent=$(echo "scale=3; $NbFound * 100 / $NbCommit"|bc)
    [ "${Pourcent:0:1}" = "." ] && Pourcent="0$Pourcent"

    echo ""
    echo " $NbFound commit(s) found ($Pourcent %)"
else
    sort $CL_libelle
fi
rm -f $ChangeLog $CL_libelle

echo   ""
printf "\033[44m ChangeLog elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit 0
