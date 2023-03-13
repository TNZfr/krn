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
    echo "Syntax : krn CompileSign Version|Archive "
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
    if [ "$Archive" = "" ]
    then
	exit 1
    fi
else
    Archive=$Param
fi

# Compilation / signature
# -----------------------
cd $(dirname $Archive)
DebDirectory=$PWD
Archive=$(basename $Archive)

# Installation des prerequis
# --------------------------
ToolsList="build-essential fakeroot dpkg-dev libssl-dev bc gnupg dirmngr libelf-dev flex bison libncurses-dev rsync git curl dwarves zstd"
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

#-------------------------------------------------------------------------------
# Compilation
#
printh "- Make bindeb-pkg (compil) ..."
make bindeb-pkg -j"$(nproc)"           \
     LOCALVERSION=-${KRN_ARCHITECTURE} \
     KDEB_PKGVERSION="$KernelVersion-krn-$(date +%Y%m%d)" > $TmpDir/Make-2-bindebpkg.log 2>&1
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
printh "- Make bindeb-pkg (relink kernel) ..."
make bindeb-pkg -j"$(nproc)"           \
     LOCALVERSION=-${KRN_ARCHITECTURE} \
     KDEB_PKGVERSION="$KernelVersion-krn-$(date +%Y%m%d)" > $TmpDir/Make-3-bindebpkg.log 2>&1
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

#-------------------------------------------------------------------------------
# Fabrication des paquets finaux 
#
printh "- Make bindeb-pkg (signed kernel) ..."
make bindeb-pkg -j"$(nproc)"           \
     LOCALVERSION=-${KRN_ARCHITECTURE} \
     KDEB_PKGVERSION="$KernelVersion-krn-$(date +%Y%m%d)" > $TmpDir/Make-4-bindebpkg.log 2>&1
CheckStatus

printh "Finalizing ..."
mv $TmpDir/linux-*.deb $DebDirectory 2>/dev/null

printh "Cleaning ..."
cd $DebDirectory
rm -rf $TmpDir $Archive /dev/shm/Compil-$$

echo ""
printf "\033[44m CompileSign $KRN_MODE elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo ""

echo "Available packages in $PWD :"
ls -lh linux-*${KernelVersion}*.deb 2>/dev/null
echo ""

exit 0
