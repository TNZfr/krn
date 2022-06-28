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
    echo "Syntax : krn Compile Archive "
    echo ""
    echo "  Archive : Linux source archive (tar.xz or tar.gz)"
    echo ""
    exit 1
fi

Archive=$1
if [ ! -f $Archive ]
then
    echo "$Archive not found."
    exit 1
fi

cd $(dirname $Archive)
RpmDirectory=$PWD
Archive=$(basename $Archive)

# Installation des prerequis
# --------------------------
InstalledPackage=/tmp/InstalledPackage-$$
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
mkdir -p $TmpDir

# Restauration archive
# --------------------
printh "Extracting archive ..."
TypeArchive=$(echo $(file $Archive|cut -d: -f2))
if [ "${TypeArchive:0:18}" = "XZ compressed data" ]
then
    tar xaf $Archive -C $TmpDir
    Directory=$(tar taf $Archive|head -1)
else
    tar xfz $Archive -C $TmpDir
    Directory=$(tar tfz $Archive|head -1)
fi

cd $TmpDir/$Directory
printh "Compiling $(basename $PWD) ..."
KernelVersion=$(make kernelversion)

if [ -L $HOME/.krn/CompilConfig ]
then
    printh "- Set owner config ($(basename $(readlink -f $HOME/.krn/CompilConfig))) ..."
    cp $HOME/.krn/CompilConfig .config
fi

printh "- Make olddefconfig ..."
make olddefconfig > $TmpDir/Make-1-olddefconfig.log 2>&1
CheckStatus

printh "- Make binrpm-pkg ..."
make binrpm-pkg -j"$(nproc)" LOCALVERSION=-"$KRN_ARCHITECTURE" > $TmpDir/Make-2-binrpmpkg.log 2>&1
CheckStatus

printh "Finalizing ..."
mv -f $(find $HOME/rpmbuild/RPMS -name "kernel*-${KernelVersion}_*.rpm") $RpmDirectory 2>/dev/null

printh "Cleaning ..."
cd $RpmDirectory
rm -rf $TmpDir $Archive

echo ""
printf "\033[44m Compile $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo ""

echo "Available packages in $PWD :"
ls -lh kernel*-${KernelVersion}_*.rpm 2>/dev/null
echo ""

exit 0
