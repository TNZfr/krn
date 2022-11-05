#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "krn.h"

//------------------------------------------------------------------------------
void ListWorkspace ()
{
}

//------------------------------------------------------------------------------
int krn_ListKernel(int NbArg, char**Arg)
{
  char *Workspace;
  char  Buffer [256];
  
  // Liste des noyaux installes
  printf ("\n");
  printf ("Current kernel : \033[34m%s\033[m\n", BashLine ("uname -r",Buffer,sizeof(Buffer)));
  printf ("Installed kernel(s)\n");
  printf ("-------------------\n");
  ListInstalledKernel();
  printf ("\n");

  // Liste des paquets / sources du depot local
  Workspace = getenv("KRN_WORKSPACE");
  if (!Workspace)
        printf ("Local workspace : \033[31mKRN_WORKSPACE not defined\033[m (cf krn Configure)\n");
  else  printf ("Local workspace : %s\n", Workspace);
  printf ("-------------------\n");
  if (Workspace) ListWorkspace ();

  if (!NbArg) return 0;

  // Recherche des noyaux dans les depots internet
  return krn_SearchKernel (NbArg, Arg);
}

/*
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
*/
