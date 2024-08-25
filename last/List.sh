#!/bin/bash

. $KRN_EXE/lib/kernel.sh

#-------------------------------------------------------------------------------
# Main
#

WorkspaceList=$KRN_WORKSPACE/.CompletionList
ModuleList=$KRN_RCDIR/.ModuleList

if [ $# -gt 0 ] && [ "$(echo $1|tr [:upper:] [:lower:])" = "force" ]
then
    # Force refresh 
    rm -f $WorkspaceList $ModuleList
fi

echo   ""
printf "Current kernel : \033[34m$(uname -r)\033[m\n"

# 1. Liste des noyaux installes
# -----------------------------
ListInstalledKernel $*

# 2. Liste des paquets compiles en local
# --------------------------------------
if [ ! -d $KRN_WORKSPACE ]
then
    echo "Local workspace $KRN_WORKSPACE not found."
    echo ""
    exit 0
fi

_RefreshWorkspaceList
NbObjet=$(cat $WorkspaceList|wc -l)
if [ $NbObjet -eq 0 ]
then
    echo " *** Empty workspace ***"
    echo ""
    exit 0
fi

echo "Local workspace : $KRN_WORKSPACE"
echo "---------------"
cat ${WorkspaceList}|linux-version-sort|cut -d',' -f1,2,3|uniq|while read Enreg 
do
    _Version="$(echo $Enreg|cut -d',' -f1)"
    _Type="$(   echo $Enreg|cut -d',' -f2)"
    _Libelle="$(echo $Enreg|cut -d',' -f3)"

    if [ "$(echo $_Libelle|grep ' Custom ')" = "" ]
    then
	_PatternVersion="%-11s"
    else
	_PatternVersion="\033[3;35m%-11s\033[m"
    fi
    
    case $_Type in
	dir)
	    _DirName=$(  echo     $_Libelle|cut -d' ' -f3)
	    _ProcessID=$(basename $_DirName|cut -d'-' -f2)
								 
	    if [ -d /proc/$_ProcessID ]
	    then
		# Compilation en cours
		printf "$_PatternVersion $_Libelle : \033[32;5mRunning\033[m\n" $_Version
	    else
		# Compilation terminée (normalement en erreur)
		printf "$_PatternVersion $_Libelle : \033[30;41mFAILED\033[m\n" $_Version
	    fi
	    ;;
	*)
	    printf "$_PatternVersion $_Libelle\n" $_Version
    esac
done
echo ""
