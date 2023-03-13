#!/bin/bash

. $KRN_EXE/_libkernel.sh

#-------------------------------------------------------------------------------
GetKernelSource ()
{
    Version=$1
    [ $(echo $Version|cut -c1) = "v" ] && Version=$(echo $Version|cut -c2-)
    Branch="v$(echo $Version|cut -c1).x"
    echo ""

    # 1.Recherche dans le repertoire de stockage
    if [ -f $KRN_WORKSPACE/linux-$Version.tar.?? ]
    then
	echo "Archive found in workspace directory : $(ls -1 $KRN_WORKSPACE/linux-$Version.tar.??)"
	return 0
    fi

    # 2. Selection de la source
    if [ "$(echo $Version|grep rc)" = "" ]
    then
	# Version stable
	Url=https://cdn.kernel.org/pub/linux/kernel/$Branch
	Archive=linux-$Version.tar.xz

	echo "cdn.kernel.org : Searching $Archive ..."
    else
	# Version RC
	Url=https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/snapshot
	Archive=linux-$Version.tar.gz

	echo "git.kernel.org : Searching $Archive ..."
    fi
    
    wget -q $Url/$Archive -O $KRN_WORKSPACE/$Archive
    Status=$?
    if [ $Status -ne 0 ]
    then 
	echo "Download error (status $Status)" 
	rm -f $KRN_WORKSPACE/$Archive
	return 1
    fi
    echo "Archive downloaded from (git/cdn).kernel.org"
    echo "Archive available : $KRN_WORKSPACE/$Archive"
}


#-------------------------------------------------------------------------------
# Main

if [ $# -lt 1 ]
then
    echo ""
    echo "Syntax : krn GetSource Version ..."
    echo ""
    echo "  Version : as it appears in krn List output command"
    echo "            or just the version number"
    echo ""
    exit 1
fi

Debut=$(TopHorloge)

for Version in $*
do
    GetKernelSource $Version 
done

echo   ""
printf "\033[44m GetSource elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit 0
