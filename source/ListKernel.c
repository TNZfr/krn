#include <stdio.h>
#include <stdlib.h>
#include <string.h>
//------------------------------------------------------------------------------
void GetCurrentVersion (char *CurrentVersion, int LgCurrentVersion)
{
  FILE *Output;
  char *Separateur;
  char  Enreg[256];

  Output = popen ("cat /proc/version|cut -d' ' -f3","r");
  fgets(CurrentVersion,LgCurrentVersion,Output);
}

//------------------------------------------------------------------------------
int krn_ListKernel(int NbArg, char**Arg)
{
  char CurrentVersion [256];

  
  // Liste des noyaux installes
  printf ("\n");
  printf ("Current kernel : \033[34m%s\033[m\n", GetCurrentVersion (CurrentVersion,sizeof(CurrentVersion)));

  // Liste des paquets / sources du depot local

  if (!NbArg) return 0;

  // Recherche des noyaux dans les depots internet
  return krn_SearchKernel (NbArg, Arg);
}



GetInstalledKernel > $InstalledKernel
NbObjet=$(cat $InstalledKernel|wc -l)
if [ $NbObjet -eq 0 ]
then
    echo ""
    echo " *** Modules directories not found."
    echo ""
    rm -rf $TmpDir
    exit 0
fi


# 1. Liste des noyaux installes
# -----------------------------
ListInstalledKernel

# 2. Liste des paquets compiles en local
# --------------------------------------
if [ ! -d $KRN_WORKSPACE ]
then
    echo "Local workspace $KRN_WORKSPACE not found."
    echo ""
    rm -rf $TmpDir
    exit 0
fi

GetWorkspaceList   > $WorkspaceList
NbObjet=$(cat $WorkspaceList|wc -l)
if [ $NbObjet -eq 0 ]
then
    echo " *** Empty workspace ***"
    echo ""
    rm -rf $TmpDir
    exit 0
fi

echo "Local workspace : $KRN_WORKSPACE"
echo "---------------"
linux-version sort <<EOF > ${WorkspaceList}.sort
$(cat $WorkspaceList) 
EOF
cat ${WorkspaceList}.sort|cut -d',' -f1,2,3|uniq| while read Enreg 
do
    _Version="$(echo $Enreg|cut -d',' -f1)"
    _Type="$(   echo $Enreg|cut -d',' -f2)"
    _Libelle="$(echo $Enreg|cut -d',' -f3)"

    case $_Type in
	dir)
	    _ProcessID=$(echo $_Libelle|tr ['\033'] [' ']|cut -d' ' -f4|cut -d- -f2)
	    if [ -d /proc/$_ProcessID ]
	    then
		# Compilation en cours
		printf "%-10s $_Libelle : \033[32;5mRunning\033[m\n" $_Version
	    else
		# Compilation terminée (normalement en erreur)
		printf "%-10s $_Libelle : \033[30;41mFAILED\033[m\n" $_Version
	    fi
	    ;;
	*)
	    printf "%-10s $_Libelle\n" $_Version
    esac
done

rm -rf $TmpDir
echo ""
[ $# -ne 0 ] && SearchKernel.sh $1
