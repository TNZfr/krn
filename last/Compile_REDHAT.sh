#!/bin/bash

. $KRN_EXE/_libkernel.sh

#-------------------------------------------------------------------------------
CheckStatus ()
{
    Status=$?
    [ $Status -eq 0 ] && return

    echo   ""
    echo   "ERROR : Return code $Status"
    echo   "        Temporary workspace $TmpDir is left as is for analysis"
    echo   ""
    echo   "        Available log files :"
    for LogFile in $TmpDir/Make-?-*.log
    do
	echo   "          $LogFile"
    done
    echo   ""
    echo   "        Don't forget to remove it because :"
    printf "        ";du -hs $TmpDir 
    echo   ""
    exit 1
}

#-------------------------------------------------------------------------------
# main
#

if [ $# -lt 1 ]
then
    echo ""
    echo "Syntax : ${KRN_Help_Prefix}Compile Version|Archive "
    echo ""
    echo "  Version : Linux version"
    echo "  Archive : Linux source archive (tar.xz or tar.gz)"
    echo ""
    exit 1
fi

Param=$1
if [ ! -f $Param ]
then
    GetSource.sh $Param
    Archive=$(ls -1 $KRN_WORKSPACE/linux-$Param.tar.?? 2>/dev/null)
    if [ "$Archive" = "" ]
    then
	exit 1
    fi
else
    Archive=$Param
fi

cd $(dirname $Archive)
RpmDirectory=$PWD
Archive=$(basename $Archive)

# Installation des prerequis
# --------------------------
InstalledPackage=$KRN_TMP/InstalledPackage-$$
printh "Verifying tools installation ..."
rpm -qa > $InstalledPackage
ToolsList="gcc flex bison elfutils-libelf-devel openssl-devel rpm-build zstd"
for Tool in $ToolsList
do
    grep -q ^$Tool $InstalledPackage
    if [ $? -ne 0 ]
    then
	$KRN_sudo yum install -y $ToolsList
	rm -f $InstalledPackage
	break 
    fi
done
rm -f $InstalledPackage

# Creation / controle espace de compilation
# -----------------------------------------
Debut=$(TopHorloge)
TmpDir=$PWD/Compil-$$
KRN_DEVSHM=$(echo $(df -m /dev/shm|grep /dev/shm)|cut -d' ' -f4); [ "$KRN_DEVSHM" = "" ] && KRN_DEVSHM=0
if [ "$KRN_DEVSHM" -gt $KRN_MINTMPFS ]
then
    FinalDir=/dev/shm/Compil-$$
    
    printh "Build temporary workspace on $FinalDir (tmpfs)"
    mkdir $FinalDir
    ln -s $FinalDir $TmpDir
else
    FinalDir=$TmpDir
    
    printh "Build temporary workspace : $TmpDir"
    mkdir -p $TmpDir
fi

# Restauration archive
# --------------------
printh "Extracting archive ..."
TypeArchive=$(echo $(file $(readlink -f $Archive)|cut -d: -f2))
if [ "${TypeArchive:0:18}" = "XZ compressed data" ]
then
    tar xaf $Archive -C $TmpDir
    Directory=$(tar taf $Archive|head -1)
else
    tar xfz $Archive -C $TmpDir
    Directory=$(tar tfz $Archive|head -1)
fi
touch $KRN_WORKSPACE # Force refresh krn List

cd $TmpDir/$Directory
printh "Compiling $(basename $PWD) ..."
KernelVersion=$(make kernelversion)

# Get config filename
CompilConfig=""
[ -L $HOME/.krn/CompilConfig ]     && CompilConfig=$(readlink -f $HOME/.krn/CompilConfig)
[ -L $KRN_WORKSPACE/CompilConfig ] && CompilConfig=$(readlink -f $KRN_WORKSPACE/CompilConfig)

if [ "$CompilConfig" != "" ]
then
    printh "- Set owner config ($(basename $CompilConfig)) ..."
    cp $CompilConfig .config
fi

printh "- Make olddefconfig ..."
make olddefconfig > $TmpDir/Make-1-olddefconfig.log 2>&1
CheckStatus

printh "- Make binrpm-pkg ..."
make binrpm-pkg -j"$(nproc)" LOCALVERSION=-"$KRN_ARCHITECTURE" > $TmpDir/Make-2-binrpmpkg.log 2>&1
CheckStatus

printh "Finalizing ..."
printh "- Final build directory size(MB) : $(echo $(du -ms $FinalDir)|cut -d' ' -f1)"
mv -f $(find $HOME/rpmbuild/RPMS -name "kernel*-${KernelVersion}_*.rpm") $RpmDirectory 2>/dev/null

printh "Cleaning ..."
cd $RpmDirectory
rm -rf $HOME/rpmbuild/BUILDROOT/* $HOME/rpmbuild/RPMS/*.rpm
rm -rf $TmpDir /dev/shm/Compil-$$ $Archive

echo ""
printf "\033[44m Compile $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo ""

echo "Available packages in $PWD :"
ls -lh kernel*-${KernelVersion}_*.rpm 2>/dev/null
echo ""

exit 0
