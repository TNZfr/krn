
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main (int NbArg, char **Arg)
{
  char *FifoName;
  int   Delay;
  
  if (NbArg < 2)
    {
      printf ("\n");
      printf ("Syntax : %s FifoName Delay\n");
      printf ("\tFifoName : Fifo to use\n");
      printf ("\tDelay .. : in seconds\n");
      printf ("\n");
      return 1;
    }

  FifoName = Arg[1];
  Delay    = atoi(Arg[2]);

  while (1)
    {
      FILE *Fifo = fopen (FifoName,"w");

      // Fifo removed, end of timer
      if (!Fifo) return 0;

      fprintf (Fifo,"Refresh\n");
      fclose  (Fifo);

      sleep (Delay);
    }

  return 0;
}
