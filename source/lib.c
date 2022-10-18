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
