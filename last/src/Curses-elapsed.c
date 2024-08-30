
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>

#include "Curses.h"

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

