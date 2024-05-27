#!/bin/bash

. $KRN_EXE/_libkernel.sh
. $KRN_EXE/curses/_libcurses.sh

#-------------------------------------------------------------------------------
CheckStatus ()
{
    Status=$?
    [ $Status -eq 0 ] && return

    (
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
    ) > $TmpDir/Error.log

    if [ "$KRNC_TMP" != "" ]
    then
	cp $TmpDir/Error.log $KRNC_ErrorLog
	_CursesStep fin $1 "\033[31mFAILED\033[m"
    fi
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

#----------------------------------------
_CursesVar KRNC_PID=$$
if [ "$Step" = "" ]
then
    CC01=CC01
    CC02=CC02
    CC03=CC03
    CC04=CC04
    CC05=CC05
    CC06=CC06
    CC07=CC07
    CC08=CC08
else
    CC01=CC${Step}a
    CC02=CC${Step}b
    CC03=CC${Step}c
    CC04=CC${Step}d
    CC05=CC${Step}e
    CC06=CC${Step}f
    CC07=CC${Step}g
    CC08=CC${Step}h
fi
_CursesStep debut $CC01 "\033[5;46m Running \033[m"
#----------------------------------------
Debut=$(TopHorloge)
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

#----------------------------------------
_CursesStep fin $CC01 "\033[22;32m$Archive\033[m"
#----------------------------------------

# Installation des prerequis
# --------------------------
_CursesStep debut $CC02 "\033[5;46m Running \033[m"
#----------------------------------------
ToolsList="debhelper build-essential fakeroot dpkg-dev libssl-dev bc gnupg dirmngr libelf-dev flex bison libncurses-dev rsync git curl dwarves zstd"
printh "Verifying tools installation ..."
Uninstalled=$(dpkg -l $ToolsList|grep -v -e "^S" -e "^|" -e "^+++" -e "^ii")
[ "$Uninstalled" != "" ] && $KRN_sudo apt install -y $ToolsList

#----------------------------------------
_CursesStep fin $CC02 "\033[22;32mInstalled\033[m"
#----------------------------------------

# Creation / controle espace de compilation
# -----------------------------------------
_CursesStep debut $CC03 "\033[5;46m Running \033[m"
#----------------------------------------
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
#----------------------------------------
_CursesStep fin $CC03 "\033[22;32m$(basename $TmpDir)\033[m"
#----------------------------------------

# Restauration archive
#----------------------------------------
printh "Extracting archive ..."
_CursesStep debut $CC04 "\033[5;46m Running \033[m"

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

#----------------------------------------
_CursesStep fin $CC04 "\033[22;32mExtracted\033[m"
#----------------------------------------

cd $TmpDir/$Directory
printh "Compiling $(basename $PWD) ..."
KernelVersion=$(make kernelversion)

# Get config filename
#----------------------------------------
_CursesStep debut $CC05 "\033[5;46m Running \033[m"
#----------------------------------------
CompilConfig=""
[ -L $HOME/.krn/CompilConfig ]     && CompilConfig=$(readlink -f $HOME/.krn/CompilConfig)
[ -L $KRN_WORKSPACE/CompilConfig ] && CompilConfig=$(readlink -f $KRN_WORKSPACE/CompilConfig)

if [ "$CompilConfig" != "" ]
then
    printh "- Set owner config ($(basename $CompilConfig)) ..."
    _CursesStep fin $CC05 "\033[m$(basename $CompilConfig)\033[m"
    cp $CompilConfig .config
else
    _CursesStep fin $CC05 "\033[22;32mCurrent\033[m"
fi

#-------------------------------------------------------------------------------
printh "- Make olddefconfig ..."
_CursesStep debut $CC06 "\033[5;46m Running \033[m"

make olddefconfig > $TmpDir/Make-1-olddefconfig.log 2>&1
CheckStatus $CC06

_CursesStep fin $CC06 "\033[22;32mDone\033[m"
#-------------------------------------------------------------------------------
printh "- Make bindeb-pkg ..."
_CursesStep debut $CC07 "\033[5;46m Running \033[m"

make bindeb-pkg -j"$(nproc)"           \
     LOCALVERSION=-"$KRN_ARCHITECTURE" \
     KDEB_PKGVERSION="$KernelVersion-krn-$(date +%Y%m%d)" > $TmpDir/Make-2-bindebpkg.log 2>&1

CheckStatus $CC07

_CursesStep fin $CC07 "\033[22;32mDone\033[m"
#-------------------------------------------------------------------------------
printh "Finalizing ..."
_CursesStep debut $CC08 "\033[5;46m Running \033[m"
mv $TmpDir/linux-*.deb $DebDirectory 2>/dev/null

printh "Cleaning ..."
cd $DebDirectory
rm -rf $TmpDir $Archive /dev/shm/Compil-$$
_CursesStep fin $CC08 "\033[22;32mDone\033[m"

#-------------------------------------------------------------------------------
echo ""
printf "\033[44m Compile $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo ""

echo "Available packages in $PWD :"
ls -lh linux-*${KernelVersion}*.deb 2>/dev/null
echo ""

exit 0
