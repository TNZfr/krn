#!/bin/bash

source $KRN_EXE/_libkernel.sh

#-------------------------------------------------------------------------------
ExitUpdate ()
{
    # Menage de fin de traitement
    rm -rf $TempDir

    echo   ""
    printf "\033[44m Upgrade Elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
    echo   ""

    exit 0
}

#-------------------------------------------------------------------------------
# Main
#
#set -x
Debut=$(TopHorloge)

[ $# -gt 0 ] && [ $(echo $1|tr [:upper:] [:lower:]) = "rc" ] && InstallRC=TRUE || InstallRC=FALSE


TempDir=$KRN_TMP/krn-update-$$
KRN_RemoteVersion=$HOME/.krn/RemoteVersion.csv

mkdir -p $TempDir

# 1. Derniere version disponible
# ------------------------------
RunningKernel=$(uname -r|cut -d'-' -f1)

#
# LastRecord    : x.y,   x.y.z, x.y-rc  (in BDD)
# LastAvailable : x.y.0, x.y.z, x.y.0-rc
#

[ ! -f $KRN_RemoteVersion ] && Update.sh

if [ $InstallRC = TRUE ]
then
    LastRecord=$(grep "rc" $KRN_RemoteVersion|tail -1|cut -d',' -f1)
    LastAvailable="$(echo $LastRecord|cut -d'-' -f1).0-$(echo $LastRecord|cut -d'-' -f2)"
else
    LastRecord=$(grep -v "\-rc" $KRN_RemoteVersion|tail -1|cut -d',' -f1)
    if [ "$(echo $LastRecord|cut -d. -f3)" = "" ]
    then
	LastAvailable=${LastRecord}.0
    else
	LastAvailable=${LastRecord}
    fi	
fi

Sorted=$(echo -e "${RunningKernel}_2\n${LastAvailable}_1"|sort|tail -1)
if [ $Sorted = ${RunningKernel}_2 ]
then
    echo ""
    echo "System is up to date. No kernel install needed."
    ExitUpdate
fi

# 2. Installation derniere version disponible
# -------------------------------------------
WorkspaceList=$KRN_WORKSPACE/.CompletionList
WorkspaceVersion=$(grep ^${LastAvailable} $WorkspaceList 2>/dev/null)

Index=$(grep -n ^${LastRecord} $KRN_RemoteVersion|head -1|cut -d':' -f1)
NbRecord=$(cat $KRN_RemoteVersion|wc -l)
    
(( NbLine = NbRecord - Index + 1 ))
echo ""
tail -$NbLine $KRN_RemoteVersion |\
    while read Record
    do
	Source=$(echo $Record|cut -d',' -f2)
	case $Source in
	    GIT|CDN) echo SRC     >> $TempDir/LastAvailable.source ;;
	    *)       echo $Source >> $TempDir/LastAvailable.source ;;
	esac
    done
sort  $TempDir/LastAvailable.source|uniq > $TempDir/LastAvailable.source.tmp
mv -f $TempDir/LastAvailable.source.tmp    $TempDir/LastAvailable.source

_RefreshWorkspaceList
grep "^${LastAvailable}," $WorkspaceList |\
    while read Record
    do
	case $(echo $Record|cut -d',' -f2) in
	    ckc        ) echo "WKS,$(echo $Record|cut -d',' -f4)" >> $TempDir/LastAvailable.source;;
	    deb|rpm|arc) echo "WKS,$(echo $Record|cut -d',' -f1)" >> $TempDir/LastAvailable.source;;
	esac
    done

echo "Kernel version ${LastAvailable} install option(s) : "
echo ""
echo "  - 0. Exit, nothing to do."
ChoiceNumber=1
cat $TempDir/LastAvailable.source|\
    while read Record
    do
	case $(echo $Record|cut -d',' -f1) in
	    SRC)
		echo "  - ${ChoiceNumber}. Download / Compile source (krn CompileInstall ${LastRecord})"
		echo "CompileInstall_${KRN_MODE}.sh ${LastRecord}" > $TempDir/Choice-${ChoiceNumber}
		;;
	    
	    UBUNTU)
		echo "  - ${ChoiceNumber}. Download / Install from Ubuntu Kernel Team (krn Install ${LastRecord})"
		echo "Install_${KRN_MODE}.sh ${LastRecord}" > $TempDir/Choice-${ChoiceNumber}
		;;
	    
	    WKS)
		wks_version=$(echo $Record|cut -d',' -f2)
		echo "  - ${ChoiceNumber}. Install from local workspace (krn Install ${wks_version})"
		echo "Install_${KRN_MODE}.sh ${wks_version}" > $TempDir/Choice-${ChoiceNumber}
		;;
	esac
	(( ChoiceNumber += 1 ))
    done
echo ""
read -p"Choice : " Choice
case $Choice in
    0) # Rien du tout
    ;;
    
    *)
	ChoiceCommand=$TempDir/Choice-${Choice}
	[ -f $ChoiceCommand ] \
	    && source $ChoiceCommand \
		|| echo "Choice #$Choice not available."
esac

ExitUpdate
