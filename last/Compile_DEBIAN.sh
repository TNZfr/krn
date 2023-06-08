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
    echo "Syntax : krn Compile Version|Archive "
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
DebDirectory=$PWD
Archive=$(basename $Archive)

# Installation des prerequis
# --------------------------
ToolsList="debhelper build-essential fakeroot dpkg-dev libssl-dev bc gnupg dirmngr libelf-dev flex bison libncurses-dev rsync git curl dwarves zstd"
printh "Verifying tools installation ..."
Uninstalled=$(dpkg -l $ToolsList|grep -v -e "^S" -e "^|" -e "^+++" -e "^ii")
[ "$Uninstalled" != "" ] && $KRN_sudo apt install -y $ToolsList

# Creation / controle espace de compilation
# -----------------------------------------
Debut=$(TopHorloge)
TmpDir=$PWD/Compil-$$
KRN_DEVSHM=$(echo $(df -m /dev/shm|grep /dev/shm)|cut -d' ' -f4); [ "$KRN_DEVSHM" = "" ] && KRN_DEVSHM=0
if [ "$KRN_DEVSHM" -gt $KRN_MINTMPFS ]
then
    printh "Build temporary workspace on /dev/shm/Compil-$$ (tmpfs)"
    mkdir /dev/shm/Compil-$$
    ln -s /dev/shm/Compil-$$ $TmpDir
else
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

printh "- Make bindeb-pkg ..."
make bindeb-pkg -j"$(nproc)"           \
     LOCALVERSION=-"$KRN_ARCHITECTURE" \
     KDEB_PKGVERSION="$KernelVersion-krn-$(date +%Y%m%d)" > $TmpDir/Make-2-bindebpkg.log 2>&1
CheckStatus

printh "Finalizing ..."
mv $TmpDir/linux-*.deb $DebDirectory 2>/dev/null

printh "Cleaning ..."
cd $DebDirectory
rm -rf $TmpDir $Archive /dev/shm/Compil-$$

echo ""
printf "\033[44m Compile $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo ""

echo "Available packages in $PWD :"
ls -lh linux-*${KernelVersion}*.deb 2>/dev/null
echo ""

exit 0
