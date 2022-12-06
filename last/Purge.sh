#!/bin/bash

. $KRN_EXE/_libkernel.sh

#-------------------------------------------------------------------------------
PurgeWorkspace ()
{
    Version=$1

    # On purge tout le workspace
    if [ "$Version" = all ]
    then	
	for Version in $(cat $WorkspaceList|cut -d',' -f1|sort|uniq|linux-version sort)
	do
	    PurgeWorkspace $Version
	done
	return
    fi

    IsInstalled=$(grep "^$Version," $InstalledKernel)
    grep "^$Version," $WorkspaceList | while read Enreg 
    do
	_Type="$(echo $Enreg|cut -d',' -f2)"
	_Libelle="$(echo $Enreg|cut -d',' -f3)"
	_Fichier="$(echo $Enreg|cut -d',' -f4)"

	case $_Type in
	    tar)
		_FreeDisk=$(du -hs $KRN_WORKSPACE/$_Fichier|tr ['\t'] [' ']|cut -d' ' -f1)
		printf "Version %-10s : $_Libelle $_Fichier purged ($_FreeDisk freed).\n" $Version
		rm -f $KRN_WORKSPACE/$_Fichier
		;;

	    deb|rpm|arc)
		if [ "$IsInstalled" != "" ]
		then
		    printf "\033[31mVersion %-10s\033[m : \033[31mINSTALLED\033[m, no purge for $_Fichier\n" $Version
		    continue
		fi

		_FreeDisk=$(du -hs $KRN_WORKSPACE/$_Fichier|tr ['\t'] [' ']|cut -d' ' -f1)
		printf "Version %-10s : $_Libelle $_Fichier purged ($_FreeDisk freed).\n" $Version
		rm -f $KRN_WORKSPACE/$_Fichier
		[ -L $KRN_WORKSPACE/$Version ] && rm -f $KRN_WORKSPACE/$Version
		;;

	    dir)
		_ProcessID=$(echo $_Fichier|cut -d- -f2)
		if [ -d /proc/$_ProcessID ]
		then
		    # Compilation en cours
		    printf "Version %-10s : \033[31mCompilation running in ${_Fichier%/}\033[m, no purge\n" $Version
		else
		    # Compilation terminée (normalement en erreur)
		    _FreeDisk=$(du -hs $KRN_WORKSPACE/$_Fichier|tr ['\t'] [' ']|cut -d' ' -f1)
		    printf "Version %-10s : Compilation directory ${_Fichier%/} purged ($_FreeDisk freed)\n" $Version
		    [ -L $KRN_WORKSPACE/$_Fichier ] && rm -rf $(readlink -f $KRN_WORKSPACE/$_Fichier)
		    rm -rf $KRN_WORKSPACE/$_Fichier
		fi
		;;
	esac
    done
}

#-------------------------------------------------------------------------------
# Main

if [ $# -lt 1 ]
then
    echo ""
    echo "Syntax : krn Purge Version ... [all]"
    echo ""
    echo "  Version : as it appears in krn List output command"
    echo "            or just the version number"
    echo "  all     : apply purge on the workspace directory"
    echo ""
    echo ""
    exit 1
fi

TmpDir=$KRN_TMP/krn-purge-$$
mkdir $TmpDir
InstalledKernel=$TmpDir/InstalledKernel
WorkspaceList=$TmpDir/WorkspaceList

Debut=$(TopHorloge)

GetInstalledKernel > $InstalledKernel
NbObjet=$(cat $InstalledKernel|wc -l)
if [ $NbObjet -eq 0 ]
then
    echo ""
    echo " *** Modules directories not found."
    echo ""
    rm -rf $TmpDir
    exit 0
fi

GetWorkspaceList   > $WorkspaceList
NbObjet=$(cat $WorkspaceList|wc -l)
if [ $NbObjet -eq 0 ]
then
    echo ""
    echo " *** Empty workspace, nothing to purge"
    echo ""
    rm -rf $TmpDir
    exit 0
fi

echo ""
SizeBefore=$(du -hs $KRN_WORKSPACE|tr ['\t'] [' ']|cut -d' ' -f1)
for Version in $*
do
    PurgeWorkspace $Version 
done
SizeAfter=$(du -hs $KRN_WORKSPACE|tr ['\t'] [' ']|cut -d' ' -f1)
echo   ""
echo   "Workspace size"
echo   "  Before purge : $SizeBefore"
echo   "  After purge  : $SizeAfter"
echo   ""
printf "\033[44m Purge elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

rm -rf $TmpDir
exit 0
