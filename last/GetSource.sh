#!/bin/bash

. $KRN_EXE/_libkernel.sh

#-------------------------------------------------------------------------------
GetKernelSource ()
{
    Version=$1
    [ $(echo $Version|cut -c1) = "v" ] && Version=$(echo $Version|cut -c2-)
    Branch="v$(echo $Version|cut -c1).x"

    InitVariable KRN_WORKSPACE dir "Workspace directory for package building and storage"
    echo ""

    # 1.Recherche dans le repertoire de stockage
    if [ -f $KRN_WORKSPACE/linux-$Version.tar.xz ]
    then
	echo "Archive found in workspace directory : $KRN_WORKSPACE/linux-$Version.tar.xz"
	return 0
    fi

    # 2.Recherche dur kernel.org
    Url=https://cdn.kernel.org/pub/linux/kernel/$Branch/
    Archive=linux-$Version.tar.xz

    echo "kernel.org : Searching $Archive ..."
    wget -q $Url/$Archive -O $KRN_WORKSPACE/$Archive
    Status=$?
    if [ $Status -ne 0 ]
    then 
	echo "Download error (status $Status)" 
	rm -f $KRN_WORKSPACE/$Archive
	return 0
    fi
    echo "Archive downloaded from kernel.org"
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
