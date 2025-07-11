#!/bin/bash

. $KRN_EXE/lib/kernel.sh

#-------------------------------------------------------------------------------
PurgeWorkspace ()
{
    Version=$1

    # On purge tout le workspace
    # --------------------------
    if [ "$Version" = all ]
    then	
	NbCKC=$(grep ",ckc," $WorkspaceList|wc -l)
	[ $NbCKC -gt 0 ] && for Object in $(grep ",ckc," $WorkspaceList|cut -d',' -f4)
	do
	    PurgeWorkspace $(basename $Object)
	done
	
	for Object in $(grep -v ",ckc," $WorkspaceList|cut -d',' -f1|sort|uniq|linux-version-sort)
	do
	    PurgeWorkspace $Object
	done

	return
    fi
 
    # Traitement des wilcards
    # -----------------------
    if [ ! -z "$(echo $Version|grep -e '*' -e '?')" ]
    then
	TmpDir=$KRN_TMP/krn-purge-$$
	mkdir $TmpDir

	for Object in $(cat $WorkspaceList|grep ",ckc,"|cut -d',' -f4)
	do touch $TmpDir/$Object;  done

	for Object in $(cat $WorkspaceList|cut -d',' -f1|sort|uniq|linux-version-sort)
	do touch $TmpDir/$Object;  done

	NbObject=$(ls -1 $TmpDir/$Version 2>/dev/null|wc -l)
	[ $NbObject -gt 0 ] && for Object in $(ls -1 $TmpDir/$Version)
	do PurgeWorkspace $(basename $Object); done
	
	_RemoveTempDirectory $TmpDir

	return
    fi
    
    ParseLinuxVersion $Version

    # Gestion des ckc
    # ---------------
    if [ ${Version:0:3} = "ckc" ]
    then
	# Noyau installe
	if [ "$(grep "^$KRN_LVBuild," $InstalledKernel)" != "" ]
	then
	    printf "\033[31mVersion %-10s\033[m : \033[31mINSTALLED\033[m, no purge for $KRN_LVCkc\n" $KRN_LVBuild
	    return
	fi

	# Compilation en cours
	CompilToDelete=""
	NbCompil=$(ls -1d $KRN_WORKSPACE/$Version/Compil-* 2>/dev/null|wc -l)
	[ $NbCompil -gt 0 ] && for Compil in $(ls -1d $KRN_WORKSPACE/$KRN_LVCkc/Compil-*)
	do
	    ProcessID=$(basename $Compil|cut -d'-' -f2)
	    if [ -d /proc/$ProcessID ]
	    then
		printf "\033[31mVersion %-10s\033[m : \033[31mRunning COMPIL\033[m, no purge for $Version\n" $KRN_LVBuild
		return
	    fi
	    CompilToDelete="$CompilToDelete $Compil /dev/shm/$(basename $Compil)"
	done
	_FreeDisk=$(du -hs $KRN_WORKSPACE/$KRN_LVCkc|tr ['\t'] [' ']|cut -d' ' -f1)
	printf "Version %-10s : $Version purged ($_FreeDisk freed).\n" $KRN_LVBuild
	rm -rf $CompilToDelete $KRN_WORKSPACE/$KRN_LVCkc
	return 
    fi

    # Gestion des paquets / sources / compilation
    # -------------------------------------------
    IsInstalled=$(grep "^$Version," $InstalledKernel)
    grep "^$KRN_LVBuild," $WorkspaceList | while read Enreg 
    do
	_Type="$(   echo $Enreg|cut -d',' -f2)"
	_Libelle="$(echo $Enreg|cut -d',' -f3)"
	_Fichier="$(echo $Enreg|cut -d',' -f4)"

	# filtre pour les ckc
	[ ${_Fichier:0:3} = "ckc" ] && continue
	
	case $_Type in
	    tar|cfg)
		_FreeDisk=$(du -hs $KRN_WORKSPACE/$_Fichier|tr ['\t'] [' ']|cut -d' ' -f1)
		printf "Version %-10s : $_Libelle $_Fichier purged ($_FreeDisk freed).\n" $KRN_LVBuild
		rm -f $KRN_WORKSPACE/$_Fichier
		;;

	    deb|rpm|pkg)
		if [ "$IsInstalled" != "" ]
		then
		    printf "\033[31mVersion %-10s\033[m : \033[31mINSTALLED\033[m, no purge for $_Fichier\n" $KRN_LVBuild
		    continue
		fi

		_FreeDisk=$(du -hs $KRN_WORKSPACE/$_Fichier|tr ['\t'] [' ']|cut -d' ' -f1)
		printf "Version %-10s : $_Libelle $_Fichier purged ($_FreeDisk freed).\n" $KRN_LVBuild
		if [ $_Type = arc ]
		then
		    rm -rf $KRN_WORKSPACE/$_Fichier
		else
		    rm -f  $KRN_WORKSPACE/$_Fichier
		fi
		[ -L $KRN_WORKSPACE/$KRN_LVBuild ] && rm -f $KRN_WORKSPACE/$KRN_LVBuild
		;;

	    dir)
		_ProcessID=$(echo $_Fichier|cut -d- -f2)
		if [ -d /proc/$_ProcessID ]
		then
		    # Compilation en cours
		    printf "Version %-10s : \033[31mCompilation running in ${_Fichier%/}\033[m, no purge\n" $KRN_LVBuild
		else
		    # Compilation terminée (normalement en erreur)
		    _FreeDisk=$(du -hs $KRN_WORKSPACE/$_Fichier|tr ['\t'] [' ']|cut -d' ' -f1)
		    printf "Version %-10s : Compilation directory ${_Fichier%/} purged ($_FreeDisk freed)\n" $KRN_LVBuild
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

Debut=$(TopHorloge)

_RefreshInstalledKernel
InstalledKernel=$KRN_RCDIR/.ModuleList

_RefreshWorkspaceList
WorkspaceList=$KRN_WORKSPACE/.CompletionList

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
exit 0
