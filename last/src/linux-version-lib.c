#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>

#include "linux-version-lib.h"

//------------------------------------------------------------------------------
void LV_Parse (LNXVER *LV, char *String)
{
  char *Suivant, *Tiret;
  char *Virgule = strchr(String,',');

  memset (LV, 0, sizeof(LNXVER));
  LV->String = String;

  if (Virgule) *Virgule='\0';

  if (LV->String[0] != 0 && strcmp(LV->String,"Unknown") != 0)
  {
    // Ignoring header for custom build
    if (!memcmp(String,"ckc-",4)) String = &String[4]; 
    
    LV->Major = (short)atoi(String);
    Suivant = strchr (String, '.');
    Suivant ++;

    LV->Minor = (short)atoi(Suivant);

    Tiret = strstr (Suivant,"-rc");
    if (Tiret)
      {
	LV->NotRC   = FALSE;
	LV->Release = (short)atoi(&Tiret[3]);
      }
    else
      {
	LV->NotRC   = TRUE;
	LV->Release = 0;

	Suivant = strchr (Suivant, '.');
	if (Suivant)
	  {
	    Suivant ++;
	    LV->Release = (short)atoi(Suivant);
	  }
      }
  }
  if (Virgule) *Virgule=',';
}
