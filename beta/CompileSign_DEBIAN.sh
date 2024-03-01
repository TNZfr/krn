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
    echo "Syntax : ${KRN_Help_Prefix}CompileSign Version|Archive "
    echo ""
    echo "  Version : Linux version"
    echo "  Archive : Linux source archive (tar.xz or tar.gz)"
    echo ""
    exit 1
fi

Debut=$(TopHorloge)
#----------------------------------------
_CursesVar KRNC_PID=$$ 
#----------------------------------------

# Controle des elements de signature
# ----------------------------------
_CursesStep debut CCS01 "\033[5;46m Running \033[m"
VerifySigningConditions
case $? in
    1) _CursesStep fin CCS01 "\033[31mParameter not defined\033[m"         ; exit 1;;
    2) _CursesStep fin CCS01 "\033[31mOne or more missing parameter\033[m" ; exit 1;;
    3) _CursesStep fin CCS01 "\033[31mMissing file(s)\033[m"               ; exit 1;;
esac
_CursesStep fin CCS01 "\033[22;32mFound\033[m"

# Controle parametres & recupération sources
# ------------------------------------------
_CursesStep debut CCS02 "\033[5;46m Running \033[m"
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
_CursesStep fin CCS02 "\033[22;32m$Archive\033[m"

# Compilation / signature
# -----------------------
cd $(dirname $Archive)
DebDirectory=$PWD
Archive=$(basename $Archive)


# Installation des prerequis
# --------------------------
_CursesStep debut CCS03 "\033[5;46m Running \033[m"
#----------------------------------------
ToolsList="debhelper build-essential fakeroot dpkg-dev libssl-dev bc gnupg dirmngr libelf-dev flex bison libncurses-dev rsync git curl dwarves zstd"
printh "Verifying tools installation ..."
Uninstalled=$(dpkg -l $ToolsList|grep -v -e "^S" -e "^|" -e "^+++" -e "^ii")
[ "$Uninstalled" != "" ] && $KRN_sudo apt install -y $ToolsList
#----------------------------------------
_CursesStep fin CCS03 "\033[22;32mInstalled\033[m"
#----------------------------------------


# Creation / controle espace de compilation
# -----------------------------------------
_CursesStep debut CCS04 "\033[5;46m Running \033[m"
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
_CursesStep fin CCS04 "\033[22;32m$TmpDir\033[m"
#----------------------------------------

# Restauration archive
# --------------------
printh "Extracting archive ..."
_CursesStep debut CCS05 "\033[5;46m Running \033[m"

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
_CursesStep fin CCS05 "\033[22;32mExtracted\033[m"
#----------------------------------------

cd $TmpDir/$Directory
printh "Compiling $(basename $PWD) ..."
KernelVersion=$(make kernelversion)

# Get config filename
#----------------------------------------
_CursesStep debut CCS06 "\033[5;46m Running \033[m"
#----------------------------------------
CompilConfig=""
[ -L $HOME/.krn/CompilConfig ]     && CompilConfig=$(readlink -f $HOME/.krn/CompilConfig)
[ -L $KRN_WORKSPACE/CompilConfig ] && CompilConfig=$(readlink -f $KRN_WORKSPACE/CompilConfig)

if [ "$CompilConfig" != "" ]
then
    printh "- Set owner config ($(basename $CompilConfig)) ..."
    _CursesStep fin CCS06 "\033[m$(basename $CompilConfig)\033[m"
    cp $CompilConfig .config
else
    _CursesStep fin CCS06 "\033[22;32mCurrent\033[m"
fi

#-------------------------------------------------------------------------------
printh "- Make olddefconfig ..."
_CursesStep debut CCS07 "\033[5;46m Running \033[m"

make olddefconfig > $TmpDir/Make-1-olddefconfig.log 2>&1
CheckStatus CCS07

_CursesStep fin CCS07 "\033[22;32mDone\033[m"
#-------------------------------------------------------------------------------
printh "- Make bindeb-pkg (compil) ..."
_CursesStep debut CCS08 "\033[5;46m Running \033[m"

make bindeb-pkg -j"$(nproc)"           \
     LOCALVERSION=-${KRN_ARCHITECTURE} \
     KDEB_PKGVERSION="$KernelVersion-krn-$(date +%Y%m%d)" > $TmpDir/Make-2-bindebpkg.log 2>&1
CheckStatus CCS08

_CursesStep fin CCS08 "\033[22;32mDone\033[m"
#-------------------------------------------------------------------------------
# Ecrasement des fichiers auto generes
#
printh "Importing signing files ..."
_CursesStep debut CCS09 "\033[5;46m Running \033[m"

export KBUILD_SIGN_PIN=$KRNSB_PASS
cp  $KRNSB_DER               certs/signing_key.x509
cat $KRNSB_PRIV $KRNSB_PEM > certs/signing_key.pem

#-------------------------------------------------------------------------------
# Relink de bzImage
#
printh "- Make bindeb-pkg (relink kernel) ..."
make bindeb-pkg -j"$(nproc)"           \
     LOCALVERSION=-${KRN_ARCHITECTURE} \
     KDEB_PKGVERSION="$KernelVersion-krn-$(date +%Y%m%d)" > $TmpDir/Make-3-bindebpkg.log 2>&1
CheckStatus CCS09

_CursesStep fin CCS09 "\033[22;32mDone\033[m"
#-------------------------------------------------------------------------------
# Signature du noyau 
#
printh "Signing kernel $Version ..."
_CursesStep debut CCS10 "\033[5;46m Running \033[m"

echo "Memory tips : $KRNSB_PASS"
Vmlinuz=arch/x86/boot/bzImage
sbsign                 \
    --key  $KRNSB_PRIV \
    --cert $KRNSB_PEM  \
    ${Vmlinuz}

mv -f ${Vmlinuz}.signed ${Vmlinuz}
echo ""

# Fabrication des paquets finaux 
printh "- Make bindeb-pkg (signed kernel) ..."
make bindeb-pkg -j"$(nproc)"           \
     LOCALVERSION=-${KRN_ARCHITECTURE} \
     KDEB_PKGVERSION="$KernelVersion-krn-$(date +%Y%m%d)" > $TmpDir/Make-4-bindebpkg.log 2>&1
CheckStatus CCS10

_CursesStep fin CCS10 "\033[22;32mDone\033[m"

#-------------------------------------------------------------------------------
printh "Finalizing ..."
_CursesStep debut CCS11 "\033[5;46m Running \033[m"
mv $TmpDir/linux-*.deb $DebDirectory 2>/dev/null

printh "Cleaning ..."
cd $DebDirectory
rm -rf $TmpDir $Archive /dev/shm/Compil-$$
_CursesStep fin CCS11 "\033[22;32mDone\033[m"

#-------------------------------------------------------------------------------
echo ""
printf "\033[44m CompileSign $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo ""

echo "Available packages in $PWD :"
ls -lh linux-*${KernelVersion}*.deb 2>/dev/null
echo ""

exit 0
