#!/bin/bash

source $KRN_EXE/_libkernel.sh

#-------------------------------------------------------------------------------
_DownloadParse_GIT ()
{
    local ListeDistante=$TempDir/git.lst
    local Archive=""
    local Version=""
    local NbVersion=0
    
    local Url=https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/refs/
    
    wget -q --no-check-certificate $Url -O $ListeDistante

    if [ "$(file $ListeDistante |cut -d: -f2|cut -d' ' -f2-4)" = "gzip compressed data," ]
    then
	mv $ListeDistante ${ListeDistante}.gz
	gunzip ${ListeDistante}.gz
    fi
    
    grep tar.gz $ListeDistante |\
	tr ['<>'] ['\n\n']     |\
	grep    ^linux         |\
	grep -v ^linux-2       |\
	while read Archive
	do
	    [ ${Archive:0:6} != "linux-" ] && continue
	    Version=${Archive%.tar.gz}
	    Version=${Version:6}
	    echo "$Version,GIT" >> $TempDir/GIT.csv
	done
    
    NbVersion="$(printf "%5d" $(cat $TempDir/GIT.csv|wc -l))"
    cat   $TempDir/GIT.csv >> $TMP_RemoteVersion
    rm -f $TempDir/GIT.csv $ListeDistante
    
    printh "GIT    = $NbVersion version(s) found"
}
#-------------------------------------------------------------------------------
_Download_Branch ()
{
    local Branch=$1
    local ListeDistante=$TempDir/cdn-$Branch
    local Archive=""
    local Version=""
    local NbVersion=0
    
    local Url=https://cdn.kernel.org/pub/linux/kernel/$Branch/
    
    wget -q --no-check-certificate $Url -O $ListeDistante

    if [ "$(file $ListeDistante |cut -d: -f2|cut -d' ' -f2-4)" = "gzip compressed data," ]
    then
	mv $ListeDistante ${ListeDistante}.gz
	gunzip ${ListeDistante}.gz
    fi
}
#-------------------------------------------------------------------------------
_DownloadParse_CDN ()
{
    local ListeDistante=$TempDir/cdn.lst
    local Version=""
    local NbVersion=0
    
    local Url=https://cdn.kernel.org/pub/linux/kernel/
    
    wget -q --no-check-certificate $Url -O $ListeDistante

    if [ "$(file $ListeDistante |cut -d: -f2|cut -d' ' -f2-4)" = "gzip compressed data," ]
    then
	mv $ListeDistante ${ListeDistante}.gz
	gunzip ${ListeDistante}.gz
    fi
    
    grep ">v..x" $ListeDistante |\
	cut -d'>' -f2        |\
	cut -d'/' -f1        |\
	while read Version
	do
	    _Download_Branch $Version
	done

    for File in $TempDir/cdn-*
    do
	local Branch=$(basename $File)
	Branch=${Branch:4}
	
	grep linux $File       |\
	    grep tar.xz        |\
	    cut -d'>' -f2      |\
	    cut -d'<' -f1      |\
	    while read Archive
	    do
		[ ${Archive:0:6} != "linux-" ] && continue
		Version=${Archive%.tar.xz}
		Version=${Version:6}
		echo "$Version,CDN" >> $TempDir/CDN-$Branch.csv
	    done
	
	NbVersion="$(printf "%5d" $(cat $TempDir/CDN-$Branch.csv|wc -l))"
	printh "CDN    = $NbVersion version(s) found for branch $Branch"
    done

    NbVersion="$(printf "%5d" $(cat $TempDir/CDN-*.csv|wc -l))"
    cat   $TempDir/CDN-*.csv >> $TMP_RemoteVersion
    rm -f $TempDir/CDN-*.csv $TempDir/cdn*

    printh "CDN    = $NbVersion version(s) found"
}
#-------------------------------------------------------------------------------
_DownloadParse_Ubuntu ()
{
    [ $KRN_MODE != DEBIAN ] && return

    local ListeDistante=$TempDir/ubuntu.lst
    local Archive=""
    local Version=""
    local NbVersion=0
    
    local Url=https://kernel.ubuntu.com/~kernel-ppa/mainline/
    
    wget -q --no-check-certificate $Url -O $ListeDistante

    if [ "$(file $ListeDistante |cut -d: -f2|cut -d' ' -f2-4)" = "gzip compressed data," ]
    then
	mv $ListeDistante ${ListeDistante}.gz
	gunzip ${ListeDistante}.gz
    fi

    grep "href=\"v" $ListeDistante |\
	cut -d'>' -f7              |\
	cut -d'/' -f1              |\
	grep -v v2.                |\
	while read Version
	do
	    echo "${Version:1},UBUNTU" >> $TempDir/Ubuntu.csv
	done
    
    NbVersion="$(printf "%5d" $(cat $TempDir/Ubuntu.csv|wc -l))"
    cat   $TempDir/Ubuntu.csv >> $TMP_RemoteVersion
    rm -f $TempDir/Ubuntu.csv $ListeDistante
    
    printh "Ubuntu = $NbVersion version(s) found"
}

#-------------------------------------------------------------------------------
# Main
#

Debut=$(TopHorloge)

TempDir=$KRN_TMP/krn-update-$$
TMP_RemoteVersion=$TempDir/RemoteVersion.csv
KRN_RemoteVersion=$HOME/.krn/RemoteVersion.csv

mkdir -p $TempDir

# 1.download / parse repositories
# -------------------------------
printh "Download repositories catalog ..."
_DownloadParse_GIT    &
_DownloadParse_CDN    &
_DownloadParse_Ubuntu &
wait
linux-version-sort $(cat $TMP_RemoteVersion) > $KRN_RemoteVersion

NbVersion=$(cat $TempDir/RemoteVersion.csv|wc -l)
printh "$NbVersion kernel vesion(s) found."

# 2. Compare with installed Kernels
# ---------------------------------
rm -rf $TempDir/*

RunningKernel=$(uname -r|cut -d'-' -f1)
Index=$(grep -n ^$RunningKernel $KRN_RemoteVersion|tail -1|cut -d':' -f1)
NbRecord=$(cat $KRN_RemoteVersion|wc -l)

if [ $Index -lt $NbRecord ]
then
    WorkspaceList=$KRN_WORKSPACE/.CompletionList
    
    (( NbLine = NbRecord - Index ))
    echo ""
    echo "New kernel version(s) available :"
    echo ""
    tail -$NbLine $KRN_RemoteVersion |\
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
			arc) echo -e "[\033[mWorkspace compil directory\033[m]"      >> $TempDir/$Version ;;
		    esac
		done
	
	Liste="$(sort $Version|tr ['\n'] [' '])"
	printf "%-12s : $Liste\n" $Version
    done
    cd $CurrentDirectory
fi

# Menage de fin de traitement
rm -rf $TempDir

echo   ""
printf "\033[44m Elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit 0
