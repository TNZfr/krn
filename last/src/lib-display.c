
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/time.h>

#include "lib-display.h"

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
	// Refresh fait dans GetUpdate
	break;

      default:
	DSP_RefreshCell (&Display->Cell[i], Prev);
      }
  }
  fflush (stdout);
  Display->Current = Prev;
}

//------------------------------------------------------------------------------
void DSP_Elapsed (CELL_ELAPSED *Cell)
{
  double ValDebut, ValFin, Delta;
  char  *Debut, *Fin;

  int  NbJour,NbHeure,NbMinute,NbSeconde,NbMilli;
  char Buffer[32];

  // Terminated ?
  if (Cell->Completed) return;

  // rien a faire
  Debut = getenv (Cell->Debut);
  Fin   = getenv (Cell->Fin);
  if (!Debut) return;

  ValDebut = atof(Debut);
  if (Fin)
  {
    ValFin = atof(Fin);
    Cell->Completed = 1;
  }
  else
  {
    struct timeval Now; //Now.tv_sec et Now.tv_usec

    gettimeofday (&Now, NULL);
    ValFin = (double) (Now.tv_sec + Now.tv_usec / 1000000);    
  }

  Delta = ValFin - ValDebut;
  if (Delta < 0.0) Delta = 0.0;
  NbSeconde = (int) Delta;
  NbMilli   = (int) ((Delta - (double) NbSeconde) * 1000.0);
  NbMinute  = NbSeconde / 60; NbSeconde %= 60;
  NbHeure   = NbMinute  / 60; NbMinute  %= 60;
  NbJour    = NbHeure   / 24; NbHeure   %= 24;

  if      (NbJour)   sprintf (Buffer,"%dd %dh %dm %ds.%03d ", NbJour,NbHeure,NbMinute,NbSeconde,NbMilli);
  else if (NbHeure)  sprintf (Buffer,"%dh %dm %ds.%03d ", NbHeure,NbMinute,NbSeconde,NbMilli);
  else if (NbMinute) sprintf (Buffer,"%dm %ds.%03d ", NbMinute,NbSeconde,NbMilli);
  else               sprintf (Buffer,"%ds.%03d ", NbSeconde,NbMilli);
  
  if (Fin) strcpy  (Cell->Buffer, Buffer);
  else     sprintf (Cell->Buffer,"%c[22;34m%s%c[m",27,Buffer,27);
}

//------------------------------------------------------------------------------
void DSP_Bash (int Row, int Col, char *Commande, char *Parametre)
{
  char  Buffer[128];
  int   NbCar;
  FILE *Desc;

  char CommandePipe[512];
  
  printf ("%c[%d;%dH", 27, Row, Col);

  sprintf (CommandePipe,"%s %d %d %s", Commande, Row, Col, Parametre);

  Desc = popen(CommandePipe,"r");
  while (!feof(Desc))
  {
    if (!fgets(Buffer,sizeof(Buffer),Desc)) continue;
    printf ("%s",Buffer);
  }
  pclose(Desc);
}

