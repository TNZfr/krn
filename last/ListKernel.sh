#!/bin/bash

. $KRN_EXE/_libkernel.sh

ListeDistante=/tmp/ListeDistante-$$.txt

Debut=$(TopHorloge)

echo   ""
printf "Current kernel : \033[34m$(uname -r)\033[m\n"

# 1. Liste des noyaux installes
# -----------------------------
echo ""
echo "Installed kernel(s)"
echo "-------------------"
if [ -d /lib/modules ]
then
    ls -1tr /lib/modules
elif [ -d /usr/lib/modules ]
then
    ls -1tr /usr/lib/modules
else
    echo "Kernel modules directory not found."
fi
# 2. Liste des paquets compiles en local
# --------------------------------------
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
for Version in $(ls -1  linux-image*.deb 2>/dev/null|cut -d_ -f2|cut -d- -f1)
do printf "$Version \033[32mDebian package (deb)\033[m\n"        >> $ListeDistante; done

# Paquets REDHAT (rpm)
for Version in $(ls -1  kernel-headers-*.rpm 2>/dev/null|cut -d- -f3|cut -d_ -f1)
do printf "$Version \033[32mRedhat package (rpm)\033[m\n"        >> $ListeDistante; done

# Repertoire pour installation
for Version in $(ls -1d *-linux-*/       2>/dev/null|cut -d- -f3|cut -d/ -f1)
do printf "$Version \033[36mCompiled kernel directory\033[m\n"   >> $ListeDistante; done

# Archives de source noyau
for Version in $(ls -1d linux-*.tar.??   2>/dev/null|cut -d- -f2|cut -d. -f1-3)
do printf "$Version \033[mKernel source archive (gz/xz)\033[m\n" >> $ListeDistante; done

SortFile $ListeDistante
rm -f    $ListeDistante
echo ""

# Si pas de critere de recherche, on sort
# ---------------------------------------
[ $# -eq 0 ] && exit 0

Version=$1
[ $(echo $Version|cut -c1) = "v" ] && Version=$(echo $Version|cut -c2-)

# 3. Recherche des source kernel.org
# ----------------------------------
Branch="v$(echo $Version|cut -c1).x"
Url=https://cdn.kernel.org/pub/linux/kernel/$Branch/
printf "Kernel.org : Getting available versions ... "
wget -q $Url -O $ListeDistante
echo "done."
echo "----------"

if [ "$(file $ListeDistante |cut -d: -f2|cut -d' ' -f2-4)" = "gzip compressed data," ]
then
    mv $ListeDistante ${ListeDistante}.gz
    gunzip ${ListeDistante}.gz
fi
ArchiveVersion=/tmp/ArchiveVersion-$$
> $ArchiveVersion
for VersionFound in $(grep tar.xz $ListeDistante|cut -d'"' -f2|rev|cut -d. -f3-|rev|cut -d- -f2|grep $Version)
do printf "$VersionFound \033[mKernel source archive (xz)\033[m\n" >> $ArchiveVersion; done
SortFile $ArchiveVersion
rm -f    $ArchiveVersion

# 4. Recherche des paquets Ubuntu/Mainline
# ----------------------------------------
Url=https://kernel.ubuntu.com/~kernel-ppa/mainline/
echo ""
printf "Ubuntu/Mainline : Getting available versions ... "
wget -q --no-check-certificate $Url -O $ListeDistante
echo "done."
echo "---------------"

# Affichage de la liste
> $ArchiveVersion
for VersionFound in $(grep "href=\"v" $ListeDistante|cut -d'>' -f7|cut -d/ -f1|cut -c2-|grep $Version)
do printf "$VersionFound \033[32mUbuntu package (deb)\033[m\n" >> $ArchiveVersion; done
SortFile $ArchiveVersion
rm -f    $ArchiveVersion

echo   ""
printf "\033[44m Elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

# Menage de fin de traitement
rm -f $ListeDistante
Status=$?

exit $Status
