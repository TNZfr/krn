
#include <stdio.h>

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
