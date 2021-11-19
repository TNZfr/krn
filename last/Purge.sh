#!/bin/bash

. $KRN_EXE/_libkernel.sh

#-------------------------------------------------------------------------------
ListeArchive ()
{
    _Pattern=""
    [ $# -gt 0 ] && _Pattern=$1

    _Liste=$(ls -1 linux-*${_Pattern}*.tar.?? 2>/dev/null)
    [ "$_Liste" != "" ] && for _Archive in $_Liste
    do
	echo ${_Archive%.tar.??}|cut -d- -f2
    done
}

#-------------------------------------------------------------------------------
CountInstalled ()
{
    PackageVersion=$1
    
    # 1. Controle du noyau en cours d'utilisation
    # -------------------------------------------
    ModulesDir=""
    [ -d /usr/lib/modules ] && ModulesDir=/usr/lib/modules
    [ -d /lib/modules ]     && ModulesDir=/lib/modules
    if [ "$ModulesDir" = "" ]
    then
	echo "ERROR : Kernel modules directory not found !"
	echo ""
	exit 1
    fi

    ModulesVersion=$(ls -1 $ModulesDir|grep ^$PackageVersion 2>/dev/null)
    if [ "$ModulesVersion" != "" ]
    then
	printf "\033[31mKernel version $PackageVersion installed\033[m, no purge\n"
	return 1
    fi
    return 0
}

#-------------------------------------------------------------------------------
MakeChoice ()
{
    case $# in
	0)
	    MakeChoice_return=""
	    ;;

	1)
	    MakeChoice_return=$1
	    ;;

	*)
	    echo "Several items found for version $Version :"
	    PS3="Select a version : "
	    LISTE=($* "None (exit)")
	    select MakeChoice_return in "${LISTE[@]}"
	    do
		[ "$MakeChoice_return" = "None (exit)" ] && echo "" && exit 0
		[ "$MakeChoice_return" != "" ] && echo "" && return 
	    done
    esac
}

#-------------------------------------------------------------------------------
PurgeWorkspace ()
{
    Version=$1
    [ $(echo $Version|cut -c1) = "v" ] && Version=$(echo $Version|cut -c2-)

    if [ "$Version" = "all" ]
    then
	ListeToPurge="Unknown"
	ListeToPurge="$ListeToPurge $(ls -1d ARCH-linux-*/      2>/dev/null|cut -d- -f3|cut -d/ -f1)"
	ListeToPurge="$ListeToPurge $(ls -1 linux-image-*.deb   2>/dev/null|cut -d_ -f2|cut -d- -f1)"
	ListeToPurge="$ListeToPurge $(ls -1 kernel-headers*.rpm 2>/dev/null|cut -d- -f3|cut -d_ -f1)"
	ListeToPurge="$ListeToPurge $(ListeArchive '')"
	for KernelVersion in $(echo $ListeToPurge|sort|uniq)
	do
	    PurgeWorkspace $KernelVersion
	done
	return
    fi
    
    # 1. Purge des paquets DEBIAN
    # ---------------------------
    VersionFound=$(ls -1 linux-image-*$Version*.deb 2>/dev/null|cut -d_ -f2|cut -d- -f1)
    if [ "$VersionFound" != "" ]
    then
	MakeChoice     $VersionFound
	CountInstalled $MakeChoice_return
	NbInstalled=$?
	if [ $NbInstalled -eq 0 ]
	then
	    NbPackage=$(ls -1 linux-*$MakeChoice_return*.deb 2>/dev/null|wc -l)
	    printf "Version %-10s : $NbPackage packages purged. \033[32mDebian package (deb)\033[m\n" $MakeChoice_return
	    rm -f linux-*$MakeChoice_return*.deb	    
	fi
    fi

    # 2. Purge des paquets RPM
    # ------------------------
    VersionFound=$(ls -1 kernel-headers-*$Version*.rpm 2>/dev/null|cut -d- -f3|cut -d_ -f1)
    if [ "$VersionFound" != "" ]
    then
	MakeChoice     $VersionFound
	CountInstalled $MakeChoice_return
	NbInstalled=$?
	if [ $NbInstalled -eq 0 ]
	then
	    NbPackage=$(ls -1 kernel-*$MakeChoice_return*.rpm 2>/dev/null|wc -l)
	    printf "Version %-10s : $NbPackage packages purged. \033[32mRedhat package (rpm)\033[m\n" $MakeChoice_return
	    rm -f kernel-*$MakeChoice_return*.rpm
	fi
    fi

    # 3.Recherche des repertoires ARCH compiles
    # -----------------------------------------
    VersionFound=$(ls -1d ARCH-linux-*$Version*/ 2>/dev/null|cut -d- -f3|cut -d/ -f1)
    if [ "$VersionFound" != "" ]
    then
	MakeChoice     $VersionFound
	CountInstalled $MakeChoice_return
	NbInstalled=$?
	if [ $NbInstalled -eq 0 ]
	then
	    FreeDisk=$(du -hs ARCH-linux-$MakeChoice_return|tr ['\t'] [' ']|cut -d' ' -f1)
	    printf "Version %-10s : \033[36mDirectory ARCH-linux-$SubVersion\033[m purged ($FreeDisk freed).\n" $MakeChoice_return
	    rm -rf ARCH-linux-$MakeChoice_return
	    [ -L $MakeChoice_return ] && rm -f $MakeChoice_return
	fi
    fi

    # 4.Recherche des archives source
    # -------------------------------
    VersionFound=$(ListeArchive $Version)
    if [ "$VersionFound" != "" ]
    then
	MakeChoice     $VersionFound
	CountInstalled $MakeChoice_return
	NbInstalled=$?
	if [ $NbInstalled -eq 0 ]
	then
	    Filename=$(ls -1 linux-$MakeChoice_return.tar.*)
	    FreeDisk=$(du -hs $Filename|tr ['\t'] [' ']|cut -d' ' -f1)
	    printf "Version %-10s : Archive $Filename purged ($FreeDisk freed).\n" $MakeChoice_return
	    rm -f linux-$MakeChoice_return.tar.??
	fi
    fi

    # 5.Repertoire de compilation
    # ---------------------------
    CompilDirList=$(ls -1d Compil*/ 2>/dev/null)
    [ "$CompilDirList" != "" ] && for CompilDir in $CompilDirList
    do
	cd $CompilDir

	SourceDir=$(ls -1d linux-*/ 2>/dev/null)
	if [ "$SourceDir" = "" ] && [ $(echo $Version|tr [:upper:] [:lower:]) = unknown ]
	then
	    cd ..
	    FreeDisk=$(du -hs $CompilDir|tr ['\t'] [' ']|cut -d' ' -f1)
	    printf "Version %-10s : \033[33mCompilation directory ${CompilDir%/}\033[m purged ($FreeDisk freed)\n" Unknown
	    rm -rf $CompilDir
	    continue
	fi
	
	cd $SourceDir
	VersionFound=$(make kernelversion 2>/dev/null)
	[ "$VersionFound" = "" ] && VersionFound=Unknown
	cd ../..
	[ $VersionFound != $Version ] && continue
	
	ProcessID=$(echo $CompilDir|cut -d- -f2)
	if [ -d /proc/$ProcessID ]
	then
	    # Compilation en cours
	    printf "Version %-10s : \033[31mCompilation running in ${CompilDir%/}\033[m, no purge\n" $Version
	else
	    # Compilation terminée (normalement en erreur)
	    FreeDisk=$(du -hs $CompilDir|tr ['\t'] [' ']|cut -d' ' -f1)
	    printf "Version %-10s : Compilation directory ${CompilDir%/} purged ($FreeDisk freed)\n" $Version
	    rm -rf $CompilDir
	fi
    done
}

#-------------------------------------------------------------------------------
# Main

if [ $# -lt 1 ]
then
    echo ""
    echo "Syntax : krn Purge Version ... [all]"
    echo ""
    echo "  Version : as it appears in krn List output command"
    echo "            or just the version number"
    echo "  all     : apply purge on the workspace directory"
    echo ""
    echo ""
    exit 1
fi

Debut=$(TopHorloge)
echo   ""

cd $KRN_WORKSPACE
SizeBefore=$(du -hs .|tr ['\t'] [' ']|cut -d' ' -f1)
for Version in $*
do
    PurgeWorkspace $Version 
done
SizeAfter=$(du -hs .|tr ['\t'] [' ']|cut -d' ' -f1)

echo   ""
echo   "Workspace size"
echo   "  Before purge : $SizeBefore"
echo   "  After purge  : $SizeAfter"
echo   ""
printf "\033[44m Purge elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit 0
