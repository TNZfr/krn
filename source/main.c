#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>
#include <ctype.h>

#include "krn.h"

//------------------------------------------------------------------------------
typedef struct
{
  char *Libelle;
  int  (*Fonction)(int NbArg, char**Arg);
  
} KRNCMD;

// ATTENTION : Garder la liste triee
int NbCommandeKRN = 33;
KRNCMD CommandeKRN[] =
  {
   "cc"               ,krn_Compile,
   "cci"              ,krn_CompilInstall,
   "ccs"              ,krn_CompileSign,
   "ccsi"             ,krn_CompilSignInstall,
   "cf"               ,krn_Configure,
   "changelog"        ,krn_ChangeLog,
   "cl"               ,krn_ChangeLog,
   "compile"          ,krn_Compile,
   "compilesign"      ,krn_CompileSign,
   "compilinstall"    ,krn_CompilInstall,
   "compilsigninstall",krn_CompilSignInstall,
   "configure"        ,krn_Configure,
   "get"              ,krn_GetKernel,
   "getsource"        ,krn_GetSource,
   "gk"               ,krn_GetKernel,
   "gs"               ,krn_GetSource,
   "install"          ,krn_InstallKernel,
   "installsign"      ,krn_InstallSignKernel,
   "is"               ,krn_InstallSignKernel,
   "list"             ,krn_ListKernel,
   "ls"               ,krn_ListKernel,
   "purge"            ,krn_Purge,
   "remove"           ,krn_RemoveKernel,
   "savelog"          ,krn_SaveLog,
   "sc"               ,krn_SetConfig,
   "se"               ,krn_SearchKernel,
   "search"           ,krn_SearchKernel,
   "setconfig"        ,krn_SetConfig,
   "sign"             ,krn_SignKernel,
   "sk"               ,krn_SignKernel,
   "sl"               ,krn_SaveLog,
   "verifykernel"     ,krn_VerifyKernel,
   "vk"               ,krn_VerifyKernel
  };

//------------------------------------------------------------------------------
void DisplayHelp()
{
  printf ("\n");
  printf (" \033[30;42m KRN v6.1 \033[m : Kernel management tool for Debian based, Redhat based and ArchLinux distributions\n");
  printf ("\n\n");
  printf ("\033[37;44m Syntax \033[m : krn Command Parameters ...\n");
  printf ("\n");
  printf ("\033[34m Workspace management \033[m\n");
  printf ("\033[34m----------------------\033[m\n");
  printf ("Configure      (CF): Display parameters. To reset, run krn configure RESET\n");
  printf ("Purge              : Remove packages and kernel build directories from workspace\n");
  printf ("\n");
  printf ("\033[34m Kernel from Local or Ubuntu/Mainline \033[m\n");
  printf ("\033[34m--------------------------------------\033[m\n");
  printf ("List           (LS): List current kernel, installed kernel and available kernels from local\n");
  printf ("Search         (SE): Search available kernels from Kernel.org (and Ubuntu/Mainline in DEBIAN mode)\n");
  printf ("\n");
  printf ("Get                : Get Debian packages from local (and Ubuntu/Mainline in DEBIAN mode)\n");
  printf ("Install            : Install selected kernel from local (and Ubuntu/Mainline in DEBIAN mode)\n");
  printf ("Remove             : Remove selected installed kernel\n");
  printf ("\n");
  printf ("Sign           (SK): Sign installed kernel (DEBIAN only)\n");
  printf ("VerifyKernel   (VK): Verify installed kernel and module signatures\n");
  printf ("InstallSign    (IS): Install and sign selected kernel (DEBIAN only)\n");
  printf ("\n");
  printf ("\033[34m Sources from kernel.org \033[m\n");
  printf ("\033[34m-------------------------\033[m\n");
  printf ("ChangeLog           (CL): Get Linux changelog file from kernel.org and display selection\n");
  printf ("GetSource           (GS): Get Linux sources archive from kernel.org\n");
  printf ("SetConfig           (SC): Display and set default config file for kernel compilation\n");
  printf ("\n");
  printf ("Compile             (CC): Compile kernel\n");
  printf ("CompilInstall      (CCI): Get sources, compile and install kernel\n");
  printf ("\n");
  printf ("CompileSign        (CCS): Compile and sign kernel (DEBIAN only)\n");
  printf ("CompilSignInstall (CCSI): Get sources, compile, sign and install kernel (DEBIAN only)\n");
  printf ("\n");
  printf ("\033[34m Log management \033[m\n");
  printf ("\033[34m----------------\033[m\n");
  printf ("SaveLog (SL)      : Save logs in directory defined by KRN_ACCOUNTING\n");
  printf ("\n");
}

//------------------------------------------------------------------------------
int LoadConfig()
{
  char  CmdNum = 0;
  FILE *Commande;
  char  Enreg[256];
  int   FreeSpace;
  
  // definition repertoire temporaire
  Commande = popen ("echo $(df -m /dev/shm|grep /dev/shm)|cut -d' ' -f4","r");
  fgets(Enreg,sizeof(Enreg),Commande);
  pclose (Commande);
  FreeSpace = atoi(Enreg);
  if (FreeSpace > 2048)
       setenv ("KRN_TMP","/dev/shm",1);
  else setenv ("KRN_TMP","/tmp",    1);

  // Chargement des varaibles KRN
  Commande = popen (". $HOME/.krn/bashrc; env|grep -e ^KRN_ -e ^KRNSB_","r");
  while (!feof(Commande))
  {
    char *Value;
      
    if (!fgets(Enreg,sizeof(Enreg),Commande)) continue;
    
    if (Enreg[strlen(Enreg)-1] == '\n') Enreg[strlen(Enreg)-1]='\0';
    Value = strchr (Enreg,'='); Value[0] = '\0'; Value ++;
    setenv (Enreg,Value,1);
  }
  pclose (Commande);
}

//------------------------------------------------------------------------------
int CompareCommande (const void *P1, const void *P2)
{
  KRNCMD *Cmd1 = (KRNCMD *) P1;
  KRNCMD *Cmd2 = (KRNCMD *) P2;
  return strcmp (Cmd1->Libelle, Cmd2->Libelle);
}

//------------------------------------------------------------------------------
int main (int NbArg, char **Arg)
{
  register int i;
  KRNCMD  *Commande;
  KRNCMD   Recherche;
  char   **Parametres;
  
  if (NbArg < 2)
    {
      DisplayHelp();
      return 0;
    }

  // Chargement de la config
  LoadConfig();

  // Parsing de la commande
  for (i=0; Arg[1][i]; i++) Arg[1][i]=(char)tolower((int)Arg[1][i]);

  Recherche.Libelle  = Arg[1];
  Recherche.Fonction = NULL;
  Commande = bsearch(&Recherche, CommandeKRN, NbCommandeKRN, sizeof(KRNCMD), CompareCommande);

  if (!Commande)
    {
      printf ("Command \033[31m%s\033[m not found\n",Arg[1]);
      return 1;
    }
  
  if (NbArg > 2)
       return Commande->Fonction (NbArg - 2, &Arg[2]);
  else return Commande->Fonction (0,NULL);
}
