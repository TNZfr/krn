#!/bin/bash

. $KRN_EXE/_libkernel.sh

#-------------------------------------------------------------------------------
CheckTool ()
{
    printf "Checking $1 ... "
    which $1 > /dev/null ; CT_Status=$?
    [ $CT_Status -eq 0 ] && echo "OK" && return

    echo "Not available"
    echo ""
    exit 1
}

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
MainDirectory=$PWD
Archive=$(basename $Archive)

# Controle des prerequis
# ----------------------
echo ""
CheckTool make
CheckTool gcc
CheckTool flex
CheckTool bison
CheckTool zstd
CheckTool cpio
echo ""

# Creation / controle espace de compilation
# -----------------------------------------
Debut=$(TopHorloge)
TmpDir=$PWD/Compil-$$
KRN_DEVSHM=$(echo $(df -m /dev/shm|grep /dev/shm)|cut -d' ' -f4); [ "$KRN_DEVSHM" = "" ] && KRN_DEVSHM=0
if [ "$KRN_DEVSHM" -gt 5120 ]
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
else
    printh "- Current config copy ..."
    zcat /proc/config.gz > .config
    CheckStatus
fi 

printh "- Make olddefconfig ..."
make olddefconfig         > $TmpDir/Make-1-olddefconfig.log 2>&1
CheckStatus

printh "- Make (bzImage) ..."
make         -j"$(nproc)" > $TmpDir/Make-2-bzimage.log 2>&1
CheckStatus

printh "- Make modules ..."
make modules -j"$(nproc)" > $TmpDir/Make-3-modules.log 2>&1
CheckStatus

printh "Finalizing ..."
cd $TmpDir
mv $Directory $MainDirectory/ARCH-$Directory 2>/dev/null

printh "Cleaning ..."
cd $MainDirectory
rm -rf $TmpDir $Archive /dev/shm/Compil-$$

echo ""
printf "\033[44m Compile $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo ""

echo "Available compiled kernel in $PWD :"
ls -dlh ARCH-linux-*/ 2>/dev/null
echo ""

exit 0
