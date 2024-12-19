
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>

#include "Curses.h"

typedef struct
{
  long Second;
  long Micro;
} SECMIC;

//------------------------------------------------------------------------------
void ParseSecMic (SECMIC *SecMic, char *String)
{
  char *Point;

  if (!String || !SecMic) return;
  Point=strchr(String,'.');

  *Point='\0';
  SecMic->Second = atoi (String);

  *Point   = '.';
  Point[7] = '\0';
  SecMic->Micro = atoi (&Point[1]);
}

//------------------------------------------------------------------------------
void DSP_Elapsed (CELL_ELAPSED *Cell)
{
  SECMIC ValDebut, ValFin, Delta;
  char  *Debut, *Fin;

  int  NbJour,NbHeure,NbMinute,NbSeconde,NbMilli,NbMicro;
  char Buffer[32];

  // Terminated ?
  if (Cell->Completed) return;

  // rien a faire
  Debut = getenv (Cell->Debut);
  Fin   = getenv (Cell->Fin);
  if (!Debut) return;

  ParseSecMic (&ValDebut, Debut);

  if (Fin)
  {
    ParseSecMic (&ValFin, Fin);
    Cell->Completed = 1;
  }
  else
  {
    struct timeval Now; //Now.tv_sec et Now.tv_usec

    gettimeofday (&Now, NULL);
    ValFin.Second = (long) Now.tv_sec;
    ValFin.Micro  = (long) Now.tv_usec;
  }

  Delta.Second = ValFin.Second - ValDebut.Second;
  Delta.Micro  = ValFin.Micro  - ValDebut.Micro;

  if (Delta.Micro < 0)
    {
      Delta.Second -= 1;
      Delta.Micro  += 1000000;
    }
  
  NbMicro   = Delta.Micro % 1000;
  NbMilli   = Delta.Micro / 1000;

  NbSeconde = (int) Delta.Second;
  NbMinute  = NbSeconde / 60; NbSeconde %= 60;
  NbHeure   = NbMinute  / 60; NbMinute  %= 60;
  NbJour    = NbHeure   / 24; NbHeure   %= 24;

  if      (NbJour)   sprintf (Buffer,"%dd %2dh %2dm %2ds.%03d", NbJour,NbHeure,NbMinute,NbSeconde,NbMilli);
  else if (NbHeure)  sprintf (Buffer,    "%2dh %2dm %2ds.%03d", NbHeure,NbMinute,NbSeconde,NbMilli);
  else if (NbMinute) sprintf (Buffer,     "    %2dm %2ds.%03d", NbMinute,NbSeconde,NbMilli);
  else               sprintf (Buffer,      "        %2ds.%03d", NbSeconde,NbMilli);
  
  if (Fin) strcpy  (Cell->Buffer, Buffer);
  else     sprintf (Cell->Buffer, "%c[22;1;34m%s", 27,Buffer);

  sprintf (&Cell->Buffer[strlen(Cell->Buffer)]," %c[22;3;36m%03d%c[m ",27,NbMicro,27);
}
