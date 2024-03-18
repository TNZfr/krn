#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>

typedef struct
{
  short Major;
  short Minor;
  short NotRC;  // RC=0, Normal=1
  short Release;

  char *String;
} LNXVER;

#define FALSE 0
#define TRUE  1

//------------------------------------------------------------------------------
void LV_Parse (LNXVER *LV, char *String)
{
  char *Suivant, *Tiret;
  char *Virgule = strchr(String,',');

  memset (LV, 0, sizeof(LNXVER));
  LV->String = String;

  if (Virgule) *Virgule='\0';

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
  if (Virgule) *Virgule=',';
}

//------------------------------------------------------------------------------
int LV_SortCompare (const void *V1, const void *V2)
{
  return memcmp (V1, V2, 4 * sizeof(short));
}

//------------------------------------------------------------------------------
int LV_Sort (LNXVER *LV, int NbLV)
{
  register int i;

  qsort (LV, NbLV, sizeof(LNXVER), LV_SortCompare);
  
  for (i=0; i<NbLV; i++) printf ("%s\n",LV[i].String);
  fflush (stdout);

  return errno;
}

//------------------------------------------------------------------------------
int SortParameter (int NbArg, char **Arg)
{
  register int i;
  LNXVER *LinuxVersion;

  LinuxVersion = malloc (sizeof(LNXVER) * NbArg);
  if (! LinuxVersion) exit (1);

  for (i=0; i< NbArg; i++) LV_Parse (&LinuxVersion[i], Arg[i]);

  return LV_Sort (LinuxVersion, NbArg);
}

//------------------------------------------------------------------------------
int SortStdin ()
{
  register int NbLV    = 0;
  register int MaxLV   = 0;
  LNXVER *LinuxVersion = NULL;
  char   *String       = NULL;
  
  FILE *Stdin;
  char  Buffer[16];

  Stdin = fdopen(STDIN_FILENO,"r");

  while (fgets(Buffer,sizeof(Buffer),Stdin))
  {
    int Last;
    int LgBuffer = strlen(Buffer);

    if (!String)
    {
      String = malloc (LgBuffer);
      if (!String) exit (1);
      memset (String, 0, LgBuffer);
    }
    else
    {
      String = realloc(String, strlen(String) + LgBuffer);
      if (!String) exit (1);
    }
    strcpy (&String[strlen(String)], Buffer);
    
    // End of record
    Last = strlen(String) - 1;
    if (String[Last] == '\n')
    {
      String[Last] = '\0';
      
      if (!LinuxVersion)
      {
	MaxLV = 32;
	LinuxVersion = malloc (MaxLV * sizeof(LNXVER));
	if (! LinuxVersion) exit (1);      
      }	
      else if (NbLV == MaxLV)
      {
	LNXVER *NewLV;

	MaxLV += 32;
	NewLV = malloc (MaxLV * sizeof(LNXVER));
	if (! NewLV) exit (1);
	
	memcpy (NewLV, LinuxVersion, NbLV * sizeof(LNXVER));
	free (LinuxVersion);
	LinuxVersion = NewLV;
      }

      LV_Parse (&LinuxVersion[NbLV], String);
      NbLV ++;
      String = NULL;
    }
  }
  return LV_Sort (LinuxVersion, NbLV);
}

//------------------------------------------------------------------------------
int main (int NbArg, char **Arg)
{
  if (NbArg > 1)
       return SortParameter (NbArg -1, &Arg[1]);
  else return SortStdin ();
}
