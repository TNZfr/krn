
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

#include "Curses.h"
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
      Cell->Type                    = ELAPSED;
      Cell->Union.Elapsed.Buffer    = Cell->Union.Elapsed.String[0];
      Cell->Union.Elapsed.Debut     = Record->Field[FIELD_PARAM1];
      Cell->Union.Elapsed.Fin       = Record->Field[FIELD_PARAM2];
      Cell->Union.Elapsed.Completed = 0;
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
    else if (!strcmp(Record->Field[FIELD_TYPE], "taillog"))
    {
      Cell->Type               = TAILLOG;
      Cell->Union.Log.TailSize = atoi(Record->Field[FIELD_PARAM1]);
      Display->NbCell ++;
    }
  }
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
int GetUpdate (DISP *Display, FILE *Fifo)
{
  char Record[512];
  char debug[1024];

  register int i;
  char *Separateur;

  if (!fgets(Record,sizeof(Record),Fifo)) return 0;

  // Top horloge
  if (strncmp(Record,"Refresh",7) == 0) return 1;

  // Status message
  if (strncmp(Record,"Step-",5) == 0)
    {
      char *Step, *Status;
	
      Step = Record;
      Separateur = strchr(Record,';');
      Separateur[0] = '\0';
      Separateur ++;

      Status = Separateur;
	
      for (i=0; i<Display->NbCell; i++)
	{
	  CELL *Cell = &Display->Cell[i];
	  int   Prev = (Display->Current + 1) % 2;

	  if (Cell->Type != STATUS) continue;
	  if (strcmp(Cell->Union.Status.File, Step) != 0) continue;

	  strcpy (Cell->Union.Status.Buffer, Status);
	  
	  // Refresh 
	  DSP_RefreshCell (Cell, Prev);
	  break;
	}
      fflush (stdout);
      return 0;
    }
    
  // Refresh des Elapsed
  if (strncmp(Record,"KRNC_",5) == 0)
    {
      CELL *Cell;
      int   Prev = (Display->Current + 1) % 2;

      Separateur = strchr (Record,'=');
      if (!Separateur) return 0;
      *Separateur='\0';
      Separateur++;
	
      setenv (Record, Separateur, 0);

      // Refresh 
      for (i=0; i<Display->NbCell; i++)
	{
	  Cell = &Display->Cell[i];
	  
	  if (Cell->Type != ELAPSED) continue;
	  if (strcmp(Record, Cell->Union.Elapsed.Debut) &&
	      strcmp(Record, Cell->Union.Elapsed.Fin  )    ) continue;

	  DSP_RefreshCell (Cell, Prev);
	  break;
	}
      fflush (stdout);
      return 0;
    }
}

//------------------------------------------------------------------------------
int main (int NbArg, char **Arg)
{
  static CSVFILE CSV;

  DISP    Display;
  FILE   *Fifo;

  int TermSize;
  int CurrentSize;

  // Named pipe reading
  Fifo = popen("tail -f $KRNC_FIFO","r");

  // Loading board
  CSV_ParseFile (&CSV, Arg[1], ',');
  LoadCell      (&Display, &CSV);

  // 1st refresh
  printf ("%c[25l",27);
  DSP_FullRefresh (&Display);
  TermSize = GetCurrentColRow ();

  // Main loop
  while (!feof(Fifo))
  {
    int ToRefresh   = GetUpdate (&Display, Fifo);
    int CurrentSize = GetCurrentColRow ();

    if (CurrentSize == TermSize && ToRefresh)
    {
      DSP_Refresh (&Display);
    }
    else if (CurrentSize != TermSize) 
    {
      TermSize = CurrentSize;
      DSP_FullRefresh (&Display);
    }

    if (getenv("KRNC_fin")) break;
  }

  // Final refresh
  GetUpdate       (&Display, Fifo);
  DSP_FullRefresh (&Display);
  printf ("%c[m%c[25h",27,27); // reset graphic attributes & Cursor ON
  fflush (stdout);

  // Cleaning & exit
  DSP_Free     (&Display);
  CSV_FreeFile (&CSV);
  fclose       (Fifo);

  return 0;
}
