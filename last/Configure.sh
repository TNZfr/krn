#!/bin/bash

. $KRN_EXE/lib/kernel.sh

#------------------------------------------------------------------------------------------------
Saisie ()
{
NomVariable=$1
Defaut=$2
Commentaire=$3

    Valeur=$(eval echo \$$NomVariable)
    [ "$Valeur" != "" ] && Defaut="$Valeur"

    printf "\033[34mIndication ............... :\033[m $Commentaire\n"
    printf "\033[34mDefault value ............ :\033[m $Defaut\n"
    printf "\033[34mValue for %-16s :\033[m " $NomVariable; read Valeur
    echo   ""

    if [ "$Valeur" = "" ]
    then
	echo "export $NomVariable=\"$Defaut\"" >> $KRN_RC
    else
	echo "export $NomVariable=\"$Valeur\"" >> $KRN_RC
    fi
}

#------------------------------------------------------------------------------------------------
TestCreateDirectory ()
{
    if [ ! -d $1 ]
    then
	printh "Creating directory : \033[34;47m$1\033[m"
	mkdir -p $1
    fi
}

#------------------------------------------------------------------------------------------------
CreateConfiguration ()
{
    if [ ! -d $KRN_RCDIR ]
    then
	mkdir -m 700 $KRN_RCDIR
    fi
    > $KRN_RC
    chmod 700 $KRN_RC

    echo "#------------------------
# User defined parameters
# -----------------------" >> $KRN_RC

    Saisie KRN_WORKSPACE      \$HOME/krn "Workspace directory for package building and storage"
    Saisie KRN_MODE           DEBIAN     "Default compilation mode (DEBIAN, REDHAT, ARCH or ARCH-CUSTOM)"
    Saisie KRN_ARCHITECTURE   amd64      "Processor Arhitecture used (amd64, arm64, armhf, ppc64el or s390x)"
    Saisie KRN_ACCOUNTING     ""         "Accounting directory"
    Saisie KRNSB_PRIV         ""         "Signing kernel : private key file full path (.priv)"
    Saisie KRNSB_PASS         ""         "Signing kernel : private key password"
    Saisie KRNSB_PEM          ""         "Signing kernel : cert file full path (.pem)"
    Saisie KRNSB_DER          ""         "Signing kernel : cert file full path (.der)"

    echo "export KRN_MINTMPFS=Unset"   >> $KRN_RC
    echo "export KRN_CONFIGUI=nconfig" >> $KRN_RC

    printh "$KRN_RC created."

    printh "Directories verification ..."
    . $KRN_RC
    TestCreateDirectory $(eval echo $KRN_WORKSPACE)
    printh "Done."
}

#------------------------------------------------------------------------------------------------
DisplayConfiguration ()
{
    echo   ""
    printf "\033[1m*** ----------------------------------------------------------------------------\033[m\n"
    printf "\033[1m*** Inside RC file \033[34m$KRN_RC\033[m\n"
    printf "\033[1m*** ----------------------------------------------------------------------------\033[m\n"
    cat $KRN_RC | while read ligne
    do
	printf "\033[1m***\033[m $ligne\n"
    done
    printf "\033[1m*** ----------------------------------------------------------------------------\033[m\n"
    echo ""
}

#------------------------------------------------------------------------------------------------
CheckInstallCompletion ()
{
    BashComp=$HOME/.bash_completion
    LocalCompletion=$KRN_RCDIR/_Completion.sh

    [ ! -f $LocalCompletion ] && \
	cp $KRN_EXE/_Completion.sh $LocalCompletion && \
	printh "Bash completion installed"

    CksVersion=$(cat $KRN_EXE/_Completion.sh | cksum)
    CksLocal=$(  cat $LocalCompletion        | cksum)
    if [ "$CksVersion" != "$CksLocal" ]
    then
	cp $KRN_EXE/_Completion.sh $LocalCompletion
	echo   ""
	printh "Bash completion upgraded"
    fi

    MissingCall=FALSE
    if [ -f $BashComp ]
    then
	grep -q "^source $LocalCompletion" $BashComp
	[ $? -eq 1 ] && MissingCall=TRUE
    else
	MissingCall=TRUE
    fi
    
    if [ $MissingCall = TRUE ]
    then
	echo   "source $LocalCompletion" >> $HOME/.bash_completion
	echo   ""
	printh "Bash completion deployed / updated"
    fi
}

#------------------------------------------------------------------------------------------------
# main
#
export KRN_RCDIR=$HOME/.krn
export KRN_RC=$KRN_RCDIR/bashrc

# En cas de RESET, on resaisie tous les parametres
# ------------------------------------------------
[ "$1" = "RESET" ] && rm -f $KRN_RC

if [ ! -f $KRN_RC ]
then
    CreateConfiguration
fi

# Appel en mode source
# --------------------
case $1 in
    LOAD)
	. $KRN_RC
    
	NbVariable=$(env|grep -e ^KRN_ -e ^KRNSB_|wc -l)
	if [ $NbVariable -lt 10 ]
	then
	    Configure.sh RESET
	    . $KRN_RC
	fi
	return
	;;

    EDIT|edit)
	[ "$(env|grep ^EDITOR)" != "" ] && $EDITOR $KRN_RC || vi $KRN_RC
	;;

    *)
esac

# Bash Completion
# ---------------
CheckInstallCompletion

# Prerequisites
# -------------
LoadModule
_VerifyTools

# Pas de parametres, affichage de la config
# -----------------------------------------
DisplayConfiguration
exit 0
