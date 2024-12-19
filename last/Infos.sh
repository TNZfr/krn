#!/bin/bash

source $KRN_EXE/lib/kernel.sh

#-------------------------------------------------------------------------------
ExitInfos ()
{
    # Menage de fin de traitement
    _RemoveTempDirectory $TempDir
    
    echo   ""
    printf "\033[44m Infos Elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
    echo   ""

    exit 0
}

#-------------------------------------------------------------------------------
# Main
#

if [ $# -lt 1 ]
then
    echo ""
    echo "Syntax : ${KRN_Help_Prefix}Infos Version [Install]"
    echo ""
    echo "  Version : as it appears in krn List output command"
    echo "            or just the version number"
    echo "  Install : display a choice list to install selected version"
    echo ""
    exit 1
fi

Debut=$(TopHorloge)

# Parsing parameters
Version=$1
ToInstall=FALSE
[ $# -gt 1 ] && [ "$(echo $2|tr [:upper:] [:lower:])" == "install" ] && ToInstall=TRUE

# Refresh des infos locales
_RefreshInstalledKernel
_RefreshWorkspaceList

ParseLinuxVersion $Version

# Controle de la BDD
KRN_RemoteVersion=$KRN_RCDIR/RemoteVersion.csv
if [ ! -f $KRN_RemoteVersion ]
then
    printh "Kernel version database update ..."
    Update.sh >/dev/null 2>&1
    printh "Done"
fi
echo    ""
echo -e "\033[30;46m Informations for $KRN_LVBuild \033[m"
echo    ""

echo -e "Last kernel version database update :\033[34m" $(stat $KRN_RemoteVersion|grep ^Modif|cut -d: -f2-|cut -d. -f1) "\033[m"
echo    ""

# Version courante
if [ ! -z "$(uname -r|grep ^${KRN_LVBuild})" ]
then
    echo -e " - \033[5;44m Current running kernel \033[m"
fi

# Version installee
Installed=$(grep "^${KRN_LVBuild}," $KRN_RCDIR/.ModuleList)
if [ ! -z "$Installed" ]
then
    echo -e " - \033[34mInstalled on current system\033[m"
fi

TempDir=$KRN_TMP/krn-infos-$$
mkdir -p $TempDir
cd       $TempDir

# Versions disponibles dans la BDD
>> Infos
grep "^${KRN_LVBuild}," $KRN_RemoteVersion| \
    while read Record
    do
	Source=$(echo $Record|cut -d',' -f2)
	case $Source in
	    GIT|CDN) echo SRC     >> Infos ;;
	    *)       echo $Source >> Infos ;;
	esac
    done

NbFound=$(cat Infos|wc -l)
if [ $NbFound -eq 0 ]
then
    echo -e "\033[31mVersion ${KRN_LVBuild} not found in database.\033[m"
    echo -e "Refresh needed ? (krn Update)"
fi

# Versions disponibles en local
WorkspaceData=$KRN_WORKSPACE/.CompletionList
[ -f $WorkspaceData ] && \
    grep "^${KRN_LVBuild}," $WorkspaceData |\
	while read Record
	do
	    case $(echo $Record|cut -d',' -f2) in
		ckc        ) echo "WKS,$(echo $Record|cut -d',' -f4)"               >> Infos;;
		deb|rpm|arc) echo "WKS,$(echo $Record|cut -d',' -f1)"               >> Infos;;
		dir        ) echo "DIR,$(echo $Record|cut -d',' -f3|cut -d' ' -f3)" >> Infos;;
	    esac
	done

# Nettoyage / tri
sort  Infos|uniq > Infos.tmp
mv -f Infos.tmp    Infos

# Affichage des infos
cat Infos|\
    while read Record
    do
	case $(echo $Record|cut -d',' -f1) in
	    SRC)    echo -e " - Sources available on kernel.org"	                       ;;
	    UBUNTU) echo -e " - \033[32mPackage available on Ubuntu Kernel Team repository\033[m" ;;
	    WKS)
		wks_version=$(echo $Record|cut -d',' -f2)
		if [ ${wks_version:0:3} = "ckc" ]
		then
		    echo -e " - \033[35mPackage available in local custom package $wks_version\033[m"
		else
		    Color="\033[32m"
		    [ ${KRN_MODE:0:4} = "ARCH" ] && Color="\033[36m"
		    
		    echo -e " - ${Color}Package available in local workspace directory\033[m"
		fi
		;;

	    DIR)
		_DirName=$(echo $Record|cut -d',' -f2)
		_ProcessID=$(basename $_DirName|cut -d'-' -f2)
		
		if [ -d /proc/$_ProcessID ]
		then
		    # Compilation en cours
		    echo -e " - \033[33mLocal build\033[m : \033[32;5mRunning\033[m"
		else
		    # Compilation terminée (normalement en erreur)
		    echo -e " - \033[33mLocal build\033[m : \033[30;41mFAILED\033[m"
		fi
		;;
	esac
    done

#-------------------------------------------------------------------------------
# Pas de compilation demandee -> sortie 
[ $ToInstall == FALSE ] && ExitInfos
#-------------------------------------------------------------------------------

VerifySigningConditions > /dev/null
CanSign=$?
echo ""
echo "Kernel version ${KRN_LVBuild} install option(s) : "
echo ""
echo "  0. Exit, nothing to do."
ChoiceNumber=1
cat Infos|\
    while read Record
    do
	case $(echo $Record|cut -d',' -f1) in
	    SRC)
		Commande=CompileInstall
		printf " %2d. %-32s (krn %-19s ${KRN_LVBuild})\n" ${ChoiceNumber} "Compile" $Commande
		echo "${Commande}.sh ${KRN_LVBuild}" > Choice-${ChoiceNumber}

		if [ $CanSign -eq 0 ]
		then
		    (( ChoiceNumber += 1 ))
		    Commande=CompileSignInstall
		    printf " %2d. %-32s (krn %-19s ${KRN_LVBuild})\n" ${ChoiceNumber} "Compile / Sign" $Commande
		    echo "${Commande}.sh ${KRN_LVBuild}" > Choice-${ChoiceNumber}
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
		       printf " %2d. %-32s (krn %-19s ${KRN_LVBuild} ${Config})\n" ${ChoiceNumber} "Compile custom $ConfigName" $Commande
		       echo "${Commande}.sh ${KRN_LVBuild} ${Config}" > Choice-${ChoiceNumber}
		   done
		   if [ $CanSign -eq 0 ]
		   then
		       for Config in $ConfigList
		       do
			   Config=$(basename $Config)
			   ConfigName=$(echo $Config|cut -d- -f3-)
			   
			   (( ChoiceNumber += 1 ))
			   Commande=ConfCompSignInst
			   printf " %2d. %-32s (krn %-19s ${KRN_LVBuild} ${Config})\n" ${ChoiceNumber} "Compile / Sign custom $ConfigName" $Commande
			   echo "${Commande}.sh ${KRN_LVBuild} ${Config}" > Choice-${ChoiceNumber}
		       done
		   fi
		fi
		;;
	    
	    UBUNTU)
		LocalPackage=$(grep "WKS,${KRN_LVBuild}" Infos)
		[ ! -z "$LocalPackage" ] && continue

		Commande=Install
		printf " %2d. %-32s (krn %s ${KRN_LVBuild})\n" ${ChoiceNumber} "Install from Ubuntu Kernel Team" $Commande
		echo "${Commande}.sh ${KRN_LVBuild}" > Choice-${ChoiceNumber}
		;;
	    
	    WKS)
		wks_version=$(echo $Record|cut -d',' -f2)
		Commande=Install
		printf " %2d. %-32s (krn %s ${wks_version})\n" ${ChoiceNumber} "Install from workspace" $Commande
		echo "${Commande}.sh ${wks_version}" > Choice-${ChoiceNumber}
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
	ChoiceCommand=Choice-${Choice}
	[ -f $ChoiceCommand ] && $(cat $ChoiceCommand) || echo "Choice #$Choice not available."
esac

ExitInfos
