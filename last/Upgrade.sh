#!/bin/bash

source $KRN_EXE/lib/kernel.sh

#-------------------------------------------------------------------------------
ExitUpgrade ()
{
    # Menage de fin de traitement
    _RemoveTempDirectory $TempDir
    
    echo   ""
    printf "\033[44m Upgrade Elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
    echo   ""

    exit 0
}

#-------------------------------------------------------------------------------
# Main
#

Debut=$(TopHorloge)
KRN_RemoteVersion=$KRN_RCDIR/RemoteVersion.csv
WorkspaceList=$KRN_WORKSPACE/.CompletionList

InstallRC=FALSE
if [ $# -gt 0 ]
then
    for Param in $(echo $*|tr [:upper:] [:lower:])
    do
	case $Param in
	    rc)      InstallRC=TRUE           ;;
	    refresh) rm -f $KRN_RemoteVersion ;;
	esac
    done
fi

TempDir=$KRN_TMP/krn-upgrade-$$
mkdir -p $TempDir

# 1. Derniere version disponible
# ------------------------------
ParseLinuxVersion $(ls -1tr /lib/modules|linux-version-sort|tail -1)
LastKernel=$KRN_LVBuild

if [ ! -f $KRN_RemoteVersion ]
then
    printh "Kernel version database update ..."
    KRN_UPGRADE=TRUE Update.sh >/dev/null 2>&1
    printh "Done"
fi

if [ $InstallRC = TRUE ]
then
    LastAvailable=$(grep    "rc"   $KRN_RemoteVersion|tail -1|cut -d',' -f1)
else
    LastAvailable=$(grep -v "\-rc" $KRN_RemoteVersion|tail -1|cut -d',' -f1)
fi

Sorted=$(echo -e "${LastKernel}_2\n${LastAvailable}_1"|linux-version-sort|tail -1)
if [ $Sorted = ${LastKernel}_2 ]
then
    echo ""
    echo "System is up to date. No kernel install needed."
    ExitUpgrade
fi

# 2. Installation derniere version disponible
# -------------------------------------------
Index=$(grep -n "^${LastAvailable}," $KRN_RemoteVersion|head -1|cut -d':' -f1)
NbRecord=$(cat $KRN_RemoteVersion|wc -l)
    
(( NbLine = NbRecord - Index + 1 ))
echo ""

# Versions disponibles dans la BDD
tail -$NbLine $KRN_RemoteVersion | grep "^${LastAvailable}," | \
    while read Record
    do
	Source=$(echo $Record|cut -d',' -f2)
	case $Source in
	    GIT|CDN) echo SRC     >> $TempDir/LastAvailable.source ;;
	    *)       echo $Source >> $TempDir/LastAvailable.source ;;
	esac
    done

# Versions disponibles en local
_RefreshWorkspaceList
[ -f $WorkspaceList ] && \
    grep "^${LastAvailable}," $WorkspaceList |\
	while read Record
	do
	    case $(echo $Record|cut -d',' -f2) in
		ckc        ) echo "WKS,$(echo $Record|cut -d',' -f4)" >> $TempDir/LastAvailable.source;;
		deb|rpm|arc) echo "WKS,$(echo $Record|cut -d',' -f1)" >> $TempDir/LastAvailable.source;;
	    esac
	done

# Nettoyage / tri
sort  $TempDir/LastAvailable.source|uniq > $TempDir/LastAvailable.source.tmp
mv -f $TempDir/LastAvailable.source.tmp    $TempDir/LastAvailable.source

VerifySigningConditions > /dev/null
CanSign=$?

echo "Kernel version ${LastAvailable} install option(s) : "
echo ""
echo "  0. Exit, nothing to do."
ChoiceNumber=1
cat $TempDir/LastAvailable.source|\
    while read Record
    do
	case $(echo $Record|cut -d',' -f1) in
	    SRC)
		Commande=CompileInstall
		printf " %2d. %-32s (krn %-19s ${LastAvailable})\n" ${ChoiceNumber} "Compile" $Commande
		echo "${Commande}.sh ${LastAvailable}" > $TempDir/Choice-${ChoiceNumber}

		if [ $CanSign -eq 0 ]
		then
		    (( ChoiceNumber += 1 ))
		    Commande=CompileSignInstall
		    printf " %2d. %-32s (krn %-19s ${LastAvailable})\n" ${ChoiceNumber} "Compile / Sign" $Commande
		    echo "${Commande}.sh ${LastAvailable}" > $TempDir/Choice-${ChoiceNumber}
		fi

		ConfigList=$(ls -1 $KRN_WORKSPACE/config-* 2>/dev/null)
		if [ ! -z "$ConfigList" ]
		then
		   for Config in $ConfigList
		   do
		       Config=$(basename $Config)
		       ConfigName=$(echo $Config|cut -d- -f3-)
		       
		       (( ChoiceNumber += 1 ))
		       Commande=ConfCompInstall
		       printf " %2d. %-32s (krn %-19s ${LastAvailable} ${Config})\n" ${ChoiceNumber} "Compile custom $ConfigName" $Commande
		       echo "${Commande}.sh ${LastAvailable} ${Config}" > $TempDir/Choice-${ChoiceNumber}
		   done
		   if [ $CanSign -eq 0 ]
		   then
		       for Config in $ConfigList
		       do
			   Config=$(basename $Config)
			   ConfigName=$(echo $Config|cut -d- -f3-)
			   
			   (( ChoiceNumber += 1 ))
			   Commande=ConfCompSignInst
			   printf " %2d. %-32s (krn %-19s ${LastAvailable} ${Config})\n" ${ChoiceNumber} "Compile / Sign custom $ConfigName" $Commande
			   echo "${Commande}.sh ${LastAvailable} ${Config}" > $TempDir/Choice-${ChoiceNumber}
		       done
		   fi
		fi
		;;
	    
	    UBUNTU)
		LocalPackage=$(grep "WKS,${LastAvailable}" $TempDir/LastAvailable.source)
		[ ! -z "$LocalPackage" ] && continue

		Commande=Install
		printf " %2d. %-32s (krn %s ${LastAvailable})\n" ${ChoiceNumber} "Install from Ubuntu Kernel Team" $Commande
		echo "${Commande}.sh ${LastAvailable}" > $TempDir/Choice-${ChoiceNumber}
		;;
	    
	    WKS)
		wks_version=$(echo $Record|cut -d',' -f2)
		Commande=Install
		printf " %2d. %-32s (krn %s ${wks_version})\n" ${ChoiceNumber} "Install from workspace" $Commande
		echo "${Commande}.sh ${wks_version}" > $TempDir/Choice-${ChoiceNumber}
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
	[ -f $ChoiceCommand ] && source $ChoiceCommand || echo "Choice #$Choice not available."
esac

ExitUpgrade
