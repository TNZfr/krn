
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/time.h>

#include "Curses.h"

//------------------------------------------------------------------------------
void DSP_Init (DISP *Display, int NbCell)
{
  register int i;
  
  memset (Display, 0, sizeof(DISP));
  Display->MaxCell = NbCell;
  Display->Cell    = malloc (NbCell * sizeof(CELL));
}

//------------------------------------------------------------------------------
void DSP_Free (DISP *Display)
{
  free (Display->Cell);
}

//------------------------------------------------------------------------------
void DSP_FullRefresh (DISP *Display)
{
  register int i,Prev;
    
  Prev = (Display->Current + 1) % 2;
  
  printf ("%c[2J%c[H",27,27);
  for (i=0; i<Display->NbCell; i++)
  {
    switch (Display->Cell[i].Type)
      {
      case UNDEFINED:
	break;
      
      case ELAPSED:
	DSP_Elapsed (&Display->Cell[i].Union.Elapsed);
	printf ("%c[%d;%dH%s%c[m",
		27,
		Display->Cell[i].Row, Display->Cell[i].Col,
		Display->Cell[i].Union.Elapsed.Buffer,
		27);
      
	Display->Cell[i].Union.Elapsed.Buffer = Display->Cell[i].Union.Elapsed.String[Prev];
	break;
      
      case STATIC:
	printf ("%c[%d;%dH%s",
		27, Display->Cell[i].Row, Display->Cell[i].Col, Display->Cell[i].Union.Static.Buffer);
	break;
      
      case STATUS:
	printf ("%c[%d;%dH%*s",
		27, Display->Cell[i].Row, Display->Cell[i].Col, Display->Cell[i].Union.Status.Size," ");
	printf ("%c[%d;%dH%s%c[m",
		27, Display->Cell[i].Row, Display->Cell[i].Col, Display->Cell[i].Union.Status.Buffer, 27);
	break;
      
      case TAILLOG:
	DSP_TailLog (Display->Cell[i].Row,
		     Display->Cell[i].Col,
		     Display->Cell[i].Union.Log.TailSize,
		     TRUE);
	break;
      
      case BASH:
	DSP_Bash (Display->Cell[i].Row,
		  Display->Cell[i].Col,
		  Display->Cell[i].Union.Bash.Buffer, "Refresh");
	break;
      
      case STATIC_BASH:
	{
	  FILE *desc;
	  char Commande[256];
	  char Resultat[256];
	
	  if (strcmp(getenv("KRN_MODE"),"DEBIAN") == 0)
	    {
	      sprintf (Commande,"echo %s",Display->Cell[i].Union.Bash.Buffer);
	    }
	  else
	    {
	      sprintf (Commande,"echo -e %s",Display->Cell[i].Union.Bash.Buffer);
	    }
       
	  desc = popen (Commande,"r");
	  fgets  (Resultat, sizeof(Resultat), desc);
	  pclose (desc);
	  printf  ("%c[%d;%dH%s",27, Display->Cell[i].Row, Display->Cell[i].Col, Resultat);
	}
      }
  }
  fflush (stdout);

  Display->Current = Prev;
}

//------------------------------------------------------------------------------
void DSP_RefreshCell (CELL *Cell, int Prev)
{
  switch (Cell->Type)
    {
    case UNDEFINED:
    case STATIC_BASH:
    case STATIC:
      break;
      
    case ELAPSED:
      DSP_Elapsed (&Cell->Union.Elapsed);
      if (strcmp(Cell->Union.Elapsed.String[0],
		 Cell->Union.Elapsed.String[1]) != 0)
	{
	  printf ("%c[%d;%dH%s%c[m",
		  27,
		  Cell->Row, Cell->Col,
		  Cell->Union.Elapsed.Buffer,
		  27);

	  strcpy (Cell->Union.Elapsed.String[Prev],
		  Cell->Union.Elapsed.Buffer       );
	}
      Cell->Union.Elapsed.Buffer = Cell->Union.Elapsed.String[Prev];
      break;
      
    case STATUS:
      if (strcmp(Cell->Union.Status.String[0],
		 Cell->Union.Status.String[1]) != 0)
	{
	  printf ("%c[%d;%dH%*s",
		  27, Cell->Row, Cell->Col,
		  Cell->Union.Status.Size," ");
	    
	  printf ("%c[%d;%dH%s%c[m",
		  27, Cell->Row, Cell->Col,
		  Cell->Union.Status.Buffer, 27);

	  strcpy (Cell->Union.Status.String[Prev],
		  Cell->Union.Status.Buffer       );
	}
      Cell->Union.Status.Buffer = Cell->Union.Status.String[Prev];
      break;
      
    case TAILLOG:
      DSP_TailLog (Cell->Row, Cell->Col, Cell->Union.Log.TailSize, FALSE);
      break;
      
    case BASH:
      DSP_Bash (Cell->Row,
		Cell->Col,
		Cell->Union.Bash.Buffer, "");
      break;
    }
}

//------------------------------------------------------------------------------
void DSP_Refresh (DISP *Display)
{
  register int i,Prev;
  
  Prev = (Display->Current + 1) % 2;

  for (i=0; i<Display->NbCell; i++)
  {
    switch (Display->Cell[i].Type)
      {
      case STATUS:
	// Refresh done in GetUpdate
	break;

      default:
	DSP_RefreshCell (&Display->Cell[i], Prev);
      }
  }
  fflush (stdout);
  Display->Current = Prev;
}
