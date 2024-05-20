
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
		27, Display->Cell[i].Row, Display->Cell[i].Col,
		Display->Cell[i].Union.Elapsed.Buffer, 27);
      
	Display->Cell[i].Union.Elapsed.Buffer = Display->Cell[i].Union.Elapsed.String[Prev];
	break;
      
      case STATIC:
	printf ("%c[%d;%dH%s",
		27, Display->Cell[i].Row, Display->Cell[i].Col,
		Display->Cell[i].Union.Static.Buffer);
	break;
      
      case STATUS:
	DSP_Status (&Display->Cell[i].Union.Status);
	printf ("%c[%d;%dH%*s",
		27, Display->Cell[i].Row, Display->Cell[i].Col,
		Display->Cell[i].Union.Status.Size," ");
	printf ("%c[%d;%dH%s%c[m",
		27, Display->Cell[i].Row, Display->Cell[i].Col,
		Display->Cell[i].Union.Status.Buffer, 27);
	break;
      
      case CURSOR:
	printf ("%c[%d;%dH%c[0J", 27, Display->Cell[i].Row, Display->Cell[i].Col,27);
	break;

      case BASH:
	DSP_Bash (Display->Cell[i].Row,
		  Display->Cell[i].Col,
		  Display->Cell[i].Union.Bash.Buffer);
	break;
      
      case STATIC_BASH:
	{
	  FILE *desc;
	  char Commande[256];
	  char Resultat[256];
	
	  sprintf (Commande,"echo %s",Display->Cell[i].Union.Bash.Buffer);
       
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
void DSP_Refresh (DISP *Display)
{
  register int i,Prev;
  
  Prev = (Display->Current + 1) % 2;
  
  for (i=0; i<Display->NbCell; i++)
  {
    switch (Display->Cell[i].Type)
      {
      case UNDEFINED:
      case STATIC_BASH:
      case STATIC:
	break;
      
      case ELAPSED:
	DSP_Elapsed (&Display->Cell[i].Union.Elapsed);
	if (strcmp(Display->Cell[i].Union.Elapsed.String[0],
		   Display->Cell[i].Union.Elapsed.String[1]) != 0)
	  {
	    printf ("%c[%d;%dH%s%c[m",
		    27, Display->Cell[i].Row, Display->Cell[i].Col,
		    Display->Cell[i].Union.Elapsed.Buffer, 27);
	  }
	Display->Cell[i].Union.Elapsed.Buffer = Display->Cell[i].Union.Elapsed.String[Prev];
	break;
      
      case STATUS:
	DSP_Status (&Display->Cell[i].Union.Status);
	if (strcmp(Display->Cell[i].Union.Status.String[0],
		   Display->Cell[i].Union.Status.String[1]) != 0)
	  {
	    printf ("%c[%d;%dH%*s",
		    27, Display->Cell[i].Row, Display->Cell[i].Col,
		    Display->Cell[i].Union.Status.Size," ");
	    
	    printf ("%c[%d;%dH%s%c[m",
		    27, Display->Cell[i].Row, Display->Cell[i].Col,
		    Display->Cell[i].Union.Status.Buffer, 27);
	  }
	Display->Cell[i].Union.Status.Buffer = Display->Cell[i].Union.Status.String[Prev];
	break;
      
      case CURSOR:
	printf ("%c[%d;%dH%c[0J", 27, Display->Cell[i].Row, Display->Cell[i].Col,27);
	break;
      
      case BASH:
	DSP_Bash (Display->Cell[i].Row,
		  Display->Cell[i].Col,
		  Display->Cell[i].Union.Bash.Buffer);
	break;
      }
  }
  fflush (stdout);
  Display->Current = Prev;
}

//------------------------------------------------------------------------------
void DSP_Elapsed (CELL_ELAPSED *Cell)
{
  double ValDebut, ValFin, Delta;
  char *Debut = getenv (Cell->Debut);
  char *Fin   = getenv (Cell->Fin);

  int  NbJour,NbHeure,NbMinute,NbSeconde,NbMilli;
  char Buffer[32];

  // rien a faire
  if (!Debut) return;

  ValDebut = atof(Debut);
  if (Fin)
  {
    ValFin = atof(Fin);
  }
  else
  {
    struct timeval Now; //Now.tv_sec et Now.tv_usec

    gettimeofday (&Now, NULL);
    ValFin = (double) (Now.tv_sec + Now.tv_usec / 1000000);    
  }

  Delta = ValFin - ValDebut;
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
void DSP_Status (CELL_STATUS *Status)
{
  char  Filename[128];
  FILE *Desc;

  Status->Buffer[0] = '\0';

  sprintf (Filename,"%s/%s",getenv("KRNC_TMP"), Status->File);
  Desc = fopen (Filename,"r");
  if (Desc)
  {
    fgets  (Status->Buffer, sizeof(Status->String[0]), Desc);
    fclose (Desc);
  }
}

//------------------------------------------------------------------------------
void DSP_Bash (int Row, int Col, char *Commande)
{
  char  Buffer[128];
  int   NbCar;
  FILE *Desc;
  
  printf ("%c[%d;%dH", 27, Row, Col);

  Desc = popen(Commande,"r");
  while (!feof(Desc))
  {
    if (!fgets(Buffer,sizeof(Buffer),Desc)) continue;
    printf ("%s",Buffer);
  }
  pclose(Desc);
}

