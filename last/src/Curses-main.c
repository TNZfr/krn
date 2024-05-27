
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

#include "lib-display.h"
#include "CSV_ParseFile.h"

//------------------------------------------------------------------------------
// Format CSV : Board, Type, Col, Row, Param1, Param2
//              0      1     2    3    4       5
#define FIELD_TYPE   1
#define FIELD_COL    2
#define FIELD_ROW    3
#define FIELD_PARAM1 4
#define FIELD_PARAM2 5

//------------------------------------------------------------------------------
void LoadCell (DISP *Display, CSVFILE *CSV)
{
  register int i;
  
  DSP_Init (Display, CSV->NbRecord);

  // Affectation des cellules
  for (i=0; i<CSV->NbRecord; i++)
  {
    CSVRECORD *Record = &CSV->Record[i];
    CELL      *Cell   = &Display->Cell[i];
    
    if (Record->NbField < 6) continue;
    
    Cell->Row = atoi (Record->Field[FIELD_ROW]);
    Cell->Col = atoi (Record->Field[FIELD_COL]);
    
    if (!strcmp(Record->Field[FIELD_TYPE], "static_bash"))
    {
      Cell->Type                    = STATIC_BASH;
      Cell->Union.StaticBash.Buffer = Record->Field[FIELD_PARAM1];
      Display->NbCell ++;
    }
    else if (!strcmp(Record->Field[FIELD_TYPE], "static"))
    {
      Cell->Type                = STATIC;
      Cell->Union.Static.Buffer = Record->Field[FIELD_PARAM1];
      Display->NbCell ++;
    }
    else if (!strcmp(Record->Field[FIELD_TYPE], "elapsed"))
    {
      Cell->Type                 = ELAPSED;
      Cell->Union.Elapsed.Buffer = Cell->Union.Elapsed.String[0];
      Cell->Union.Elapsed.Debut  = Record->Field[FIELD_PARAM1];
      Cell->Union.Elapsed.Fin    = Record->Field[FIELD_PARAM2];
      Display->NbCell ++;
    }
    else if (!strcmp(Record->Field[FIELD_TYPE], "bash"))
    {
      Cell->Type              = BASH;
      Cell->Union.Bash.Buffer = Record->Field[FIELD_PARAM1];
      Display->NbCell ++;
    }
    else if (!strcmp(Record->Field[FIELD_TYPE], "status"))
    {
      Cell->Type                = STATUS;
      Cell->Union.Status.File   = Record->Field[FIELD_PARAM1];
      Cell->Union.Status.Size   = atoi(Record->Field[FIELD_PARAM2]);
      Cell->Union.Status.Buffer = Cell->Union.Status.String[0];
      Display->NbCell ++;
    }
    else if (!strcmp(Record->Field[FIELD_TYPE], "cursor"))
    {
      Cell->Type = CURSOR;
      Display->NbCell ++;
    }
  }
}

//------------------------------------------------------------------------------
void LoadVarFile ()
{
  char Record[32];
  FILE *Desc = fopen (getenv("KRNC_VAR"),"r");

  while (!feof(Desc))
  {
    char *Separateur;

    if (!fgets(Record,sizeof(Record),Desc)) continue;

    Separateur = strchr (Record,'=');
    if (!Separateur) continue;
    *Separateur='\0';
    Separateur++;

    setenv (Record, Separateur, 1);
  }
  fclose(Desc);
}

//------------------------------------------------------------------------------
int GetCurrentColRow ()
{
  char Record[32];
  int   ReturnValue;
  FILE *Desc = popen ("tput lines cols","r");

  ReturnValue = 1;
  while (!feof(Desc))
  {
    char *Separateur;

    if (!fgets(Record,sizeof(Record),Desc)) continue;
    ReturnValue *= atoi(Record);
  }
  fclose(Desc);
  return ReturnValue;
}

//------------------------------------------------------------------------------
int main (int NbArg, char **Arg)
{
  DISP    Display;
  CSVFILE CSV;

  int TermSize;
  int CurrentSize;

    
  // Chargement des donnees
  CSV_ParseFile (&CSV, Arg[1], ',');
  LoadCell      (&Display, &CSV);
  LoadVarFile   ();

  // 1er affichage
  DSP_FullRefresh (&Display);
  TermSize = GetCurrentColRow ();

  // Boucle principale
  while (!getenv("KRNC_fin"))
  {
    LoadVarFile ();
    CurrentSize = GetCurrentColRow ();
    if (CurrentSize == TermSize)
    {
      DSP_Refresh (&Display);
    }
    else
    {
      TermSize = CurrentSize;
      DSP_FullRefresh (&Display);
    }
    sleep       (1);
  }
  LoadVarFile ();
  DSP_Refresh (&Display);
  printf ("%c[m",27); // reset graphic attributes

  // Menage & sortie
  DSP_Free     (&Display);
  CSV_FreeFile (&CSV);
  return 0;
}
