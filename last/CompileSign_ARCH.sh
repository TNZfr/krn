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
    echo "Syntax : ${KRN_Help_Prefix}CompileSign Version|Archive "
    echo ""
    echo "  Version : Linux version"
    echo "  Archive : Linux source archive (tar.xz or tar.gz)"
    echo ""
    exit 1
fi

# Controle des elements de signature
# ----------------------------------
VerifySigningConditions

# Controle parametres & recupération sources
# ------------------------------------------
Param=$1
if [ ! -f $Param ]
then
    GetSource.sh $Param
    Archive=$(ls -1 $KRN_WORKSPACE/linux-$Param.tar.?? 2>/dev/null)
    [ "$Archive" = "" ] && exit 1
else
    Archive=$Param
fi

# Compilation / signature
# -----------------------
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

#-------------------------------------------------------------------------------
# Compilation
#
printh "- Make (bzImage compil) ..."
make -j"$(nproc)" > $TmpDir/Make-2-bzimage.log 2>&1
CheckStatus
printh "- Make modules (compil) ..."
make modules -j"$(nproc)" > $TmpDir/Make-3-modules.log 2>&1
CheckStatus

#-------------------------------------------------------------------------------
# Ecrasement des fichiers auto generes
#
printh "Importing signing files ..."
export KBUILD_SIGN_PIN=$KRNSB_PASS
cp  $KRNSB_DER               certs/signing_key.x509
cat $KRNSB_PRIV $KRNSB_PEM > certs/signing_key.pem

#-------------------------------------------------------------------------------
# Relink de bzImage
#
printh "- Make (relink kernel) ..."
make -j"$(nproc)" > $TmpDir/Make-4-bzimage.log 2>&1
CheckStatus

#-------------------------------------------------------------------------------
# Signature du noyau 
#
printh "Signing kernel $Version ..."
echo "Memory tips : $KRNSB_PASS"
Vmlinuz=arch/x86/boot/bzImage
sbsign                 \
    --key  $KRNSB_PRIV \
    --cert $KRNSB_PEM  \
    ${Vmlinuz}

mv -f ${Vmlinuz}.signed ${Vmlinuz}
echo ""

printh "Signing kernel modules $Version ..."
export KBUILD_SIGN_PIN=$KRNSB_PASS

for ModuleBinary in $(find . -name "*.ko")
do
    scripts/sign-file \
	sha256        \
	$KRNSB_PRIV   \
	$KRNSB_DER    \
	$ModuleBinary
done
#-------------------------------------------------------------------------------
printh "Finalizing ..."
find -name *.o -exec rm {} \;
cd $TmpDir
mv $Directory $MainDirectory/ARCH-$Directory 2>/dev/null

printh "Cleaning ..."
cd $Mainirectory
rm -rf $TmpDir $Archive /dev/shm/Compil-$$

echo ""
printf "\033[44m CompileSign $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo ""

echo "Available compiled kernel in $PWD :"
ls -1 ARCH-linux-* 2>/dev/null|linux-version sort
echo ""

exit 0
