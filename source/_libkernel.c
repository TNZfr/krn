#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "CSV_ParseRecord.h"

//------------------------------------------------------------------------------
char *BashLine (char *CommandLine, char *Buffer, int LgBuffer)
{
  FILE *Output;

  Output = popen (CommandLine,"r");
  fgets  (Buffer,LgBuffer,Output);
  pclose (Output);

  return Buffer;
}

//------------------------------------------------------------------------------
void BashList (char *CommandLine,
		char *Buffer, int LgBuffer,
		void (*CallBack)(char *Buffer))
{
  FILE *Output;

  Output = popen (CommandLine,"r");
  while (!feof(Output))
    {
      if (!fgets (Buffer,LgBuffer,Output)) continue;
      CallBack (Buffer);
    }
  pclose (Output);
}

//------------------------------------------------------------------------------
void GetInstalledKernel (char *Buffer, int LgBuffer, void (*CallBack)(char *Buffer))
{
   FILE *Output;
   char *rc;
   char *separateur;
   char version [256];
   char VersionCourte[256];

  Output = popen ("linux-version sort $(ls -1 /usr/lib/modules)","r");
  while (!feof(Output))
    {
      if (!fgets (version,sizeof(version),Output)) continue;

      separateur = strchr(version,'\n');
      if (separateur) *separateur='\0';
      
      strcpy (VersionCourte, version);

      rc = strstr(VersionCourte,"rc");
      if (!rc) rc = VersionCourte;
      separateur = strchr (rc, '-');      
      *separateur = '\0';

      sprintf (Buffer,"%s,%s,/usr/lib/modules/%s",VersionCourte, version, version);
      CallBack (Buffer);
    }
  pclose (Output);
}

//------------------------------------------------------------------------------
void CB_InstalledKernel (char *Buffer)
{
  char     *separateur;
  char      taille [128];
  _CSVPARSE Enreg;

  // Format buffer : VersionCourte, VersionLongue, CheminComplet
  if (!CSV_ParseOneRecord (Buffer, ',', &Enreg)) return;

  setenv   ("KRN_P1", Enreg.Field[2], 1);
  BashLine ("du -hs $KRN_P1", taille, sizeof(taille));
  separateur = strchr(taille, '\t');
  if (separateur) *separateur = '\0';

  printf ("%-20s \033[36mModule directory size\033[m %s\n", Enreg.Field[1], taille); 
}

//------------------------------------------------------------------------------
void ListInstalledKernel ()
{
  char Buffer [256];
  
  GetInstalledKernel (Buffer,sizeof(Buffer),CB_InstalledKernel);
}
