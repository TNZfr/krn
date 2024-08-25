#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>

#include "linux-version-lib.h"

//------------------------------------------------------------------------------
int main (int NbArg, char **Arg)
{
  LNXVER VersionNum;
  
  if (NbArg < 2)
    {
      printf ("\n");
      printf ("Syntax : %s LinuxVersion\n", Arg[0]);
      printf ("\tLinuxVersion : x.y or x.y.z or x.y-rc\n");
      printf ("\n");
      return 1;
    }
  
  LV_Parse (&VersionNum, Arg[1]);
  printf   ("%d%03d%1d%03d\n",
	    VersionNum.Major,
	    VersionNum.Minor,
	    VersionNum.NotRC,
	    VersionNum.Release);
  return 0;
}
