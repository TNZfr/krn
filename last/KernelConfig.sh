#!/bin/bash

. $KRN_EXE/lib/kernel.sh && LoadModule

#-------------------------------------------------------------------------------
# main
#

if [ $# -lt 2 ]
then
    echo ""
    echo "Syntax : ${KRN_Help_Prefix}KernelConfig Version|Archive Label [default|KernelConfig]"
    echo ""
    echo "  Version .... : Linux version"
    echo "  Archive .... : Linux source archive (tar.xz or tar.gz)"
    echo "  Label ...... : Configuration label"
    echo ""
    echo "  default .... : Use default kernel config"
    echo "  KernelConfig : Use existant kernel config file as source"
    echo ""
    exit 1
fi


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

Libelle=$2

# Selection de la config racine
KRN_DEFCONFIG="olddefconfig"
if [ $# -eq 3 ]
then
    case $3 in
	default)
	    KRN_DEFCONFIG="defconfig"
	    ;;
	*)
	    [ -f $KRN_WORKSPACE/$3 ] && KRN_DEFCONFIG=$KRN_WORKSPACE/$3
    esac
fi

cd $(dirname $Archive)
CurrentDirectory=$PWD
Archive=$(basename $Archive)

# Installation des prerequis
# --------------------------
_VerifyTools COMPIL

# Creation / controle espace de compilation
# -----------------------------------------
_CreateCompileDirectory

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
printh "Configuring $(basename $PWD) ..."
KernelVersion=$(make kernelversion)
FinalConfig=$KRN_WORKSPACE/config-${KernelVersion}-${Libelle}

if [ -f $KRN_DEFCONFIG ]
then
    printh "- Resume from existing $(basename $KRN_DEFCONFIG)"
    cp -f $KRN_DEFCONFIG .config
else
    printh "- Make $KRN_DEFCONFIG ..."
    make $KRN_DEFCONFIG > $TmpDir/Make-1-${KRN_DEFCONFIG}.log 2>&1
fi

[ "$KRN_CONFIGUI" = "" ] && export KRN_CONFIGUI=nconfig
printh "- Make $KRN_CONFIGUI ..."
make $KRN_CONFIGUI 

printh "Finalizing ..."
cp .config $FinalConfig
printh "$FinalConfig created."

printh "Cleaning ..."
cd $CurrentDirectory
_RemoveTempDirectory $TmpDir

echo ""
printf "\033[44m KernelConfig elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo ""

echo "Available Config files in $PWD :"
ls -lh config-*-* 2>/dev/null
echo ""

exit 0
