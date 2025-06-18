#!/bin/bash

. $KRN_EXE/lib/kernel.sh && LoadModule
. $KRN_EXE/curses/_libcurses.sh

#-------------------------------------------------------------------------------
CheckStatus ()
{
    Status=$?
    [ $Status -eq 0 ] && return

    _CursesStep fin $1 "\033[31mFAILED\033[m"

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
    echo "Syntax : ${KRN_Help_Prefix}CompileSign Version|Archive "
    echo ""
    echo "  Version : Linux version"
    echo "  Archive : Linux source archive (tar.xz or tar.gz)"
    echo ""
    exit 1
fi

#----------------------------------------
if [ "$Step" = "" ]
then
    CCS01=CCS01
    CCS02=CCS02
    CCS03=CCS03
    CCS04=CCS04
    CCS05=CCS05
    CCS06=CCS06
    CCS07=CCS07
    CCS08=CCS08
    CCS09=CCS09
    CCS10=CCS10
    CCS11=CCS11
else
    CCS01=CCS${Step}a
    CCS02=CCS${Step}b
    CCS03=CCS${Step}c
    CCS04=CCS${Step}d
    CCS05=CCS${Step}e
    CCS06=CCS${Step}f
    CCS07=CCS${Step}g
    CCS08=CCS${Step}h
    CCS09=CCS${Step}i
    CCS10=CCS${Step}j
    CCS11=CCS${Step}k
fi
#----------------------------------------

Debut=$(TopHorloge)
Param=$1

# Controle des elements de signature
# ----------------------------------
_CursesStep debut $CCS01 "\033[5;46m Running \033[m"
VerifySigningConditions
case $? in
    1) _CursesStep fin $CCS01 "\033[31mParameter not defined\033[m"         ; exit 1;;
    2) _CursesStep fin $CCS01 "\033[31mOne or more missing parameter\033[m" ; exit 1;;
    3) _CursesStep fin $CCS01 "\033[31mMissing file(s)\033[m"               ; exit 1;;
esac
_CursesStep fin   $CCS01 "\033[22;32mFound\033[m"

# Source Archive
# --------------
_CursesStep debut $CCS02 "\033[5;46m Running \033[m"
if [ ! -f $Param ]
then
    ParseLinuxVersion $Param

    GetSource.sh $KRN_LVArch
    Archive=$(ls -1 $KRN_WORKSPACE/linux-${KRN_LVArch}.tar.?? 2>/dev/null)
    if [ "$Archive" = "" ]
    then
	_CursesStep fin $CCS01 "\033[31mNo source archive\033[m"
	exit 1
    fi
else
    Archive=$Param
fi
_CursesStep fin   $CCS02 "\033[22;32m$(basename $Archive)\033[m"


# Compilation / signature
# -----------------------
cd $(dirname $Archive)
CurrentDirectory=$PWD
Archive=$(basename $Archive)

# Installation des prerequis
# --------------------------
_CursesStep  debut $CCS03 "\033[5;46m Running \033[m"
_VerifyTools COMPIL
_CursesStep  fin   $CCS03 "\033[22;32mInstalled\033[m"

# Creation / controle espace de compilation
# ------------------------------------------
_CursesStep debut $CCS04 "\033[5;46m Running \033[m"
_CreateCompileDirectory
_CursesStep fin   $CCS04 "\033[22;32m$(basename $TmpDir)\033[m"

# Restauration archive
# --------------------
printh "Extracting archive ..."
_CursesStep debut $CCS05 "\033[5;46m Running \033[m"

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

_CursesStep fin   $CCS05 "\033[22;32mExtracted\033[m"
#----------------------------------------

cd $TmpDir/$Directory
printh "Compiling $(basename $PWD) ..."
KernelVersion=$(make kernelversion)

# Overload function and procedure
# -------------------------------
_OverloadModule $KernelVersion

# Get config filename
#--------------------
_CursesStep debut $CCS06 "\033[5;46m Running \033[m"

CompilConfig=""
[ -L $HOME/.krn/CompilConfig ]     && CompilConfig=$(readlink -f $HOME/.krn/CompilConfig)
[ -L $KRN_WORKSPACE/CompilConfig ] && CompilConfig=$(readlink -f $KRN_WORKSPACE/CompilConfig)

if [ "$CompilConfig" != "" ]
then
    printh "- Set owner config ($(basename $CompilConfig)) ..."
    _CursesStep fin $CCS06 "\033[m$(basename $CompilConfig)\033[m"
    cp $CompilConfig .config
else
    _SetCurrentConfig
    _CursesStep fin $CCS06 "\033[22;32mCurrent\033[m"
fi

#-------------------------------------------------------------------------------
printh "- Make olddefconfig ..."
_CursesStep debut $CCS07 "\033[5;46m Running \033[m"

make olddefconfig > $TmpDir/Make-1-olddefconfig.log 2>&1
CheckStatus $CCS07

_CursesStep fin   $CCS07 "\033[22;32mDone\033[m"
#-------------------------------------------------------------------------------
# Compilation principale
#
_CursesStep debut $CCS08 "\033[5;46m Running \033[m"

_MakePkgSign1 $TmpDir/Make-2-pkg.log
CheckStatus $CCS08

_CursesStep fin   $CCS08 "\033[22;32mDone\033[m"
#-------------------------------------------------------------------------------
# Import fichiers signature et signature noyau
#
_CursesStep debut $CCS09 "\033[5;46m Running \033[m"
printh "Importing signing files ..."

export KBUILD_SIGN_PIN=$KRNSB_PASS
cp  $KRNSB_DER               certs/signing_key.x509
cat $KRNSB_PRIV $KRNSB_PEM > certs/signing_key.pem

# Signature du noyau 
# ------------------
printh "Signing kernel $Version ..."

echo "Memory tips : $KRNSB_PASS"
Vmlinuz=$(make image_name)
sbsign                           \
    --key  certs/signing_key.pem \
    --cert certs/signing_key.pem \
    ${Vmlinuz}

mv -f ${Vmlinuz}.signed ${Vmlinuz}
echo ""

_CursesStep fin   $CCS09 "\033[22;32mDone\033[m"
#-------------------------------------------------------------------------------
# Rebuild package
#
_CursesStep debut $CCS10 "\033[5;46m Running \033[m"

# Update Makefile
mv  arch/x86/Makefile arch/x86/Makefile.original
cat arch/x86/Makefile.original|sed 's/bzImage: vmlinux/bzImage: $(KBUILD_IMAGE)/g' > arch/x86/Makefile

# Fabrication des paquets finaux 
_MakePkgSign2 $TmpDir/Make-3-pkg.log
CheckStatus   $CCS10

_CursesStep fin   $CCS10 "\033[22;32mDone\033[m"
#-------------------------------------------------------------------------------
_CursesStep debut $CCS11 "\033[5;46m Running \033[m"

printh "Finalizing ..."
if [ $KRN_MINTMPFS = Unset ]
then
    printh "- Final build directory size(MB) : $(echo $(du -ms $FinalDir)|cut -d' ' -f1)"
    printh "- Use \"krn configure edit\" command to set KRN_MINTMPFS"
    printh "- with a value a little bit greater than the one displayed"
fi
_Finalize

printh "Cleaning ..."
_CleanBuildDirectories

_CursesStep fin   $CCS11 "\033[22;32mDone\033[m"
#-------------------------------------------------------------------------------
echo ""
printf "\033[44m CompileSign $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo ""

echo "Available packages in $PWD :"
_ListAvailable
echo ""

exit 0
