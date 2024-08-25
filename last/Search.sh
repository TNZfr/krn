#!/bin/bash

. $KRN_EXE/lib/kernel.sh

Debut=$(TopHorloge)

# Si pas de critere de recherche, on sort
# ---------------------------------------
if [ $# -eq 0 ]
then
    echo ""
    echo "Syntax : ${KRN_Help_Prefix}Search Version"
    echo ""
    echo "  Version : as it appears in krn List output command"
    echo "            or just the version number"
    echo ""
    exit 1
fi

RemoteVersion=$KRN_RCDIR/RemoteVersion.csv
WorkspaceList=$KRN_WORKSPACE/.CompletionList

[ ! -f $RemoteVersion ] && Update.sh

TempDir=$KRN_TMP/krn-search-$$
mkdir -p $TempDir

echo ""
echo "Availability : "
echo -e "\t\033[32mUbuntu\033[m ................... : Debian Package from PPA Kernel Ubuntu"
echo -e "\t\033[32mWorkspace deb package\033[m .... : Local Debian package"
echo -e "\t\033[32mWorkspace rpm package\033[m .... : Local Redhat package"
echo -e "\t\033[36mWorkspace KRN/Arch package\033[m : Local KRN/Arch package"
echo -e "\t\033[mWorkspace directory\033[m ...... : Local directory (Arch / Gentoo)"
echo -e "\tGit / Cdn ................ : Sources from kernel.org for compilation"
echo -e "\t\033[35mckc-\033[3mVersion-Label\033[m ........ : Local custom kernel packages"
echo ""
echo -e "Database update :\033[34m" $(stat $RemoteVersion|grep ^Modify|cut -c9-27) "\033[m(krn Update to refresh database)"
echo ""

grep "^$1" $RemoteVersion |\
    while read Record
    do
	Version=$(echo $Record|cut -d',' -f1)
	Source=$( echo $Record|cut -d',' -f2)
	
	case $Source in
	    GIT)    echo -e "\033[mGit\033[m" >> $TempDir/$Version ;;
	    CDN)    echo -e "\033[mCdn\033[m" >> $TempDir/$Version ;;
	    UBUNTU) echo -e "\033[32mUbuntu\033[m" >> $TempDir/$Version ;;
	esac

    done

CurrentDirectory=$PWD
cd $TempDir
for Version in $(linux-version-sort *)
do
    [ -f $WorkspaceList ] && \
	grep "^${Version}," $WorkspaceList |\
	    while read Record
	    do
		case $(echo $Record|cut -d',' -f2) in
		    ckc) echo -e "[\033[35m$(echo $Record|cut -d',' -f4)\033[m]" >> $TempDir/$Version ;;
		    deb) echo -e "[\033[32mWorkspace deb package\033[m]"         >> $TempDir/$Version ;;
		    rpm) echo -e "[\033[32mWorkspace rpm package\033[m]"         >> $TempDir/$Version ;;
		    pkg) echo -e "[\033[36mWorkspace KRN/Archpackage\033[m]"     >> $TempDir/$Version ;;
		    arc) echo -e "[\033[mWorkspace directory\033[m]"             >> $TempDir/$Version ;;
		    dir) echo -e "[\033[33mWorkspace build\033[m]"               >> $TempDir/$Version ;;
		esac
	    done
    
    Liste="$(cat $Version|tr ['\n'] [' '])"
    printf "%-12s : $Liste\n" $Version
done
NbVersion=$(ls -1|wc -l)

NbSource=$(grep -e Cdn -e Git *|wc -l)
NbUbuntu=$(grep Ubuntu        *|wc -l)
NbCKC=$(   grep ckc           *|wc -l)
NbLocal=$( grep Workspace     *|wc -l)

# Cleaning
cd $CurrentDirectory
_RemoveTempDirectory $TempDir

echo ""
echo "Found $NbVersion kernel version(s) :"
echo -e "\t$NbSource on kernel.org"
echo -e "\t$NbUbuntu in PPA Kernel Ubuntu"
echo -e "\t$NbLocal in local repository"
echo -e "\t$NbCKC custom in local repository"
echo ""
echo -e "\033[44m Elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))"
echo ""

exit 0
