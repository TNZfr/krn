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
    echo "Syntax : krn Compil Archive ..."
    echo ""
    echo "  Archive : Linux source archive from kernel.org"
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
DebDirectory=$PWD
Archive=$(basename $Archive)

# Installation des prerequis
# --------------------------
printh "Verifying tools installation ..."
sudo apt install -y  \
     build-essential fakeroot   dpkg-dev       \
     perl            libssl-dev bc             \
     gnupg           dirmngr    libelf-dev     \
     flex            bison      libncurses-dev \
     rsync           git        curl           \
     dwarves

# Creation / controle espace de compilation
# -----------------------------------------
Debut=$(TopHorloge)
printh "Creating temporary workspace ..."
TmpDir=$PWD/Compil-$$
mkdir -p $TmpDir

# Restauration archive
# --------------------
printh "Extracting archive ..."
if [ "$(echo $(file $Archive)|cut -d: -f2)" = " XZ compressed data" ]
then
    tar xaf $Archive -C $TmpDir
    Directory=$(tar taf $Archive|head -1)
else
    tar xfz $Archive -C $TmpDir
    Directory=$(tar tfz $Archive|head -1)
fi

cd $TmpDir/$Directory
printh "Compiling $(basename $PWD)..."
KernelVersion=$(make kernelversion)
make olddefconfig ; CheckStatus
make deb-pkg    -j"$(nproc)" LOCALVERSION=-"$(dpkg --print-architecture)" KDEB_PKGVERSION="$KernelVersion-krn-$(date +%Y%m%d)" ; CheckStatus
make bindeb-pkg -j"$(nproc)" LOCALVERSION=-"$(dpkg --print-architecture)" KDEB_PKGVERSION="$KernelVersion-krn-$(date +%Y%m%d)" ; CheckStatus

echo ""
printh "Finalizing ..."
mv $TmpDir/linux-*.deb $DebDirectory 2>/dev/null
cd $DebDirectory
rm -rf $TmpDir

echo ""
printf "\033[44m Elapsed time \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo ""

echo "Available packages in $PWD :"
ls -lh linux-*${KernelVersion}*.deb 2>/dev/null
echo ""

exit 0
