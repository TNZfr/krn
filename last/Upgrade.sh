#!/bin/bash

source $KRN_EXE/_libkernel.sh

#-------------------------------------------------------------------------------
ExitUpgrade ()
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
ParseLinuxVersion $(ls -1tr /lib/modules|linux-version-sort|tail -1)
LastKernel=$KRN_LVBuild

[ ! -f $KRN_RemoteVersion ] && Update.sh

if [ $InstallRC = TRUE ]
then
    LastAvailable=$(grep    "rc"   $KRN_RemoteVersion|tail -1|cut -d',' -f1)
else
    LastAvailable=$(grep -v "\-rc" $KRN_RemoteVersion|tail -1|cut -d',' -f1)
fi

Sorted=$(echo -e "${LastKernel}_2\n${LastAvailable}_1"|sort|tail -1)
if [ $Sorted = ${LastKernel}_2 ]
then
    echo ""
    echo "System is up to date. No kernel install needed."
    ExitUpgrade
fi

# 2. Installation derniere version disponible
# -------------------------------------------
WorkspaceList=$KRN_WORKSPACE/.CompletionList
WorkspaceVersion=$(grep ^${LastAvailable} $WorkspaceList 2>/dev/null)

Index=$(grep -n "^${LastAvailable}," $KRN_RemoteVersion|head -1|cut -d':' -f1)
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
		echo "  - ${ChoiceNumber}. Download / Compile source (krn CompileInstall ${LastAvailable})"
		echo "CompileInstall_${KRN_MODE}.sh ${LastAvailable}" > $TempDir/Choice-${ChoiceNumber}
		;;
	    
	    UBUNTU)
		echo "  - ${ChoiceNumber}. Download / Install from Ubuntu Kernel Team (krn Install ${LastAvailable})"
		echo "Install_${KRN_MODE}.sh ${LastAvailable}" > $TempDir/Choice-${ChoiceNumber}
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

ExitUpgrade
