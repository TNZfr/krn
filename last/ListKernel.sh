#!/bin/bash

. $KRN_EXE/_libkernel.sh

ListeDistante=/tmp/ListeDistante-$$.txt

echo   ""
printf "Current kernel : \033[34m$(uname -r)\033[m\n"

# 1. Liste des noyaux installes
# -----------------------------
echo ""
echo "Installed kernel(s)"
echo "-------------------"
ModuleDirectory=""
if [ -d /lib/modules ]
then
    ModuleDirectory=/lib/modules
elif [ -d /usr/lib/modules ]
then
    ModuleDirectory=/usr/lib/modules
else
    echo "Kernel modules directory not found."
fi

if [ "$ModuleDirectory" != "" ]
then    
    linux-version sort <<EOF
$(cd $ModuleDirectory; du -hs *|while read line; do printf "%-20s \033[36mModule directory size\033[m %s\n" $(echo $line|cut -d' ' -f2) $(echo $line|cut -d' ' -f1);done)
EOF
fi

# 2. Liste des paquets compiles en local
# --------------------------------------
if [ ! -d $KRN_WORKSPACE ]
then
    echo ""
    echo "Local workspace $KRN_WORKSPACE not found."
    echo ""
    exit 0
fi

echo ""
echo "Local workspace : $KRN_WORKSPACE"
echo "---------------"
cd $KRN_WORKSPACE
CompilDirList=$(ls -1d Compil*/ 2>/dev/null)
[ "$CompilDirList" != "" ] && for CompilDir in $CompilDirList
do
    cd $CompilDir

    SourceDir=$(ls -1d linux-*/ 2>/dev/null)
    if [ "$SourceDir" = "" ]
    then
	cd ..
	printf "%-10s \033[33mCompilation directory ${CompilDir%/}\033[m\n" Unknown
	continue
    fi
    
    cd $SourceDir
    Version=$(make kernelversion 2>/dev/null)
    [ "$Version" = "" ] && Version=Unknown
    cd ../..
    ProcessID=$(echo $CompilDir|cut -d- -f2)

    if [ -d /proc/$ProcessID ]
    then
	# Compilation en cours
	printf "%-10s \033[33mCompilation directory %-13s : \033[32;5mRunning\033[m\n" $Version ${CompilDir%/}
    else
	# Compilation terminée (normalement en erreur)
	printf "%-10s \033[33mCompilation directory %-13s : \033[30;41mFAILED\033[m\n" $Version ${CompilDir%/}
    fi
done

# Paquets DEBIAN (deb)
> $ListeDistante
for Version in $(ls -1  linux-image*.deb 2>/dev/null|cut -d_ -f2|cut -d- -f1)
do printf "%-10s \033[32mDebian package (deb)\033[m\n" $Version        >> $ListeDistante; done

# Paquets REDHAT (rpm)
for Version in $(ls -1  kernel-headers-*.rpm 2>/dev/null|cut -d- -f3|cut -d_ -f1)
do printf "%-10s \033[32mRedhat package (rpm)\033[m\n" $Version        >> $ListeDistante; done

# Repertoire pour installation
for Version in $(ls -1d *-linux-*/       2>/dev/null|cut -d- -f3|cut -d/ -f1)
do printf "%-10s \033[36mCompiled kernel directory\033[m\n" $Version   >> $ListeDistante; done

# Archives de source noyau
for Version in $(ls -1d linux-*.tar.??   2>/dev/null|cut -d- -f2|cut -d. -f1-3)
do printf "%-10s \033[mKernel source archive (gz/xz)\033[m\n" $Version >> $ListeDistante; done

linux-version sort <<EOF
$(cat $ListeDistante)
EOF
rm -f    $ListeDistante
echo ""

if [ $# -ne 0 ]
then
    SearchKernel.sh $1
fi
