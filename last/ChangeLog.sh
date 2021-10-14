#!/bin/bash

. $KRN_EXE/_libkernel.sh

#-------------------------------------------------------------------------------
# Main

if [ $# -lt 1 ]
then
    echo ""
    echo "Syntax : krn ChangeLog Version [Pattern] [...]"
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
    for Pattern in $(echo $* |cut -d' ' -f2-)
    do
	AllPattern="$AllPattern -e $Pattern"
    done
fi

Directory=v$(echo $Version|cut -d. -f1).x
URL=https://cdn.kernel.org/pub/linux/kernel/$Directory/ChangeLog-$Version
ChangeLog=/tmp/changelog-$$
wget -q $URL -O $ChangeLog 2>/dev/null

# Comptage des commits
NbCommit=$(grep ^commit $ChangeLog|wc -l)
((NbCommit -= 1))

echo ""
echo "--- $NbCommit commit(s) for kernel version $Version ---"
echo ""

if [ "$AllPattern" != "None" ]
then
    curl $URL 2>/dev/null | \
	grep -A4 ^commit  | \
	while read Line; do	[ "$Line" = "--" ] && echo $PrevLine; PrevLine=$Line; done | \
	sort | \
	grep $AllPattern
else
    curl $URL 2>/dev/null | \
	grep -A4 ^commit  | \
	while read Line; do	[ "$Line" = "--" ] && echo $PrevLine; PrevLine=$Line; done | \
	sort
fi
rm -f $ChangeLog

echo   ""
printf "\033[44m ChangeLog elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit 0
