#!/bin/bash

. $KRN_EXE/_libkernel.sh

#-------------------------------------------------------------------------------
PurgeWorkspace ()
{
    Version=$1

    # On purge tout le workspace
    # --------------------------
    if [ "$Version" = all ]
    then	
	NbCKC=$(ls -1d $KRN_WORKSPACE/ckc-*-* 2>/dev/null|wc -l)
	[ $NbCKC -gt 0 ] && for Version in $(ls -1d $KRN_WORKSPACE/ckc-*-*)
	do
	    PurgeWorkspace $Version
	done
	
	for Version in $(cat $WorkspaceList|cut -d',' -f1|sort|uniq|linux-version sort)
	do
	    PurgeWorkspace $Version
	done

	return
    fi

    # Gestion des ckc
    # ---------------
    if [ ${Version:0:3} = "ckc" ]
    then
	if [ "$(echo $Version|grep rc)" = "" ]
	then
	    CKC_Version=$(echo $Version|cut -d'-' -f2)
	else
	    CKC_Version=$(echo $Version|cut -d'-' -f2,3)
	fi
	
	# Noyau installe
	if [ "$(grep "^$CKC_Version," $InstalledKernel)" != "" ]
	then
	    printf "\033[31mVersion %-10s\033[m : \033[31mINSTALLED\033[m, no purge for $_Fichier\n" $CKC_Version
	    return
	fi

	# Compilation en cours
	CompilToDelete=""
	NbCompil=$(ls -1d $KRN_WORKSPACE/$Version/Compil-* 2>/dev/null|wc -l)
	[ $NbCompil -gt 0 ] && for Compil in $(ls -1d $KRN_WORKSPACE/$Version/Compil-*)
	do
	    ProcessID=$(basename $Compil|cut -d'-' -f2)
	    if [ -d /proc/$ProcessID ]
	    then
		printf "\033[31mVersion %-10s\033[m : \033[31mRunning COMPIL\033[m, no purge for $Version\n" $CKC_Version
		return
	    fi
	    CompilToDelete="$CompilToDelete $Compil /dev/shm/$(basename $Compil)"
	done
	_FreeDisk=$(du -hs $KRN_WORKSPACE/$Version|tr ['\t'] [' ']|cut -d' ' -f1)
	printf "Version %-10s : $Version purged ($_FreeDisk freed).\n" $CKC_Version
	rm -rf $CompilToDelete $KRN_WORKSPACE/$Version
	return 
    fi

    # Gestion des paquets / sources / compilation
    # -------------------------------------------
    IsInstalled=$(grep "^$Version," $InstalledKernel)
    grep "^$Version," $WorkspaceList | while read Enreg 
    do
	_Type="$(   echo $Enreg|cut -d',' -f2)"
	_Libelle="$(echo $Enreg|cut -d',' -f3)"
	_Fichier="$(echo $Enreg|cut -d',' -f4)"

	# filtre pour les ckc
	[ ${_Fichier:0:3} = "ckc" ] && continue
	
	case $_Type in
	    tar|cfg)
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
		if [ $_Type = arc ]
		then
		    rm -rf $KRN_WORKSPACE/$_Fichier
		else
		    rm -f  $KRN_WORKSPACE/$_Fichier
		fi
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
    echo "Syntax : ${KRN_Help_Prefix}Purge Version ... [all]"
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
WorkspaceList=$KRN_WORKSPACE/.CompletionList

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

_RefreshWorkspaceList
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
