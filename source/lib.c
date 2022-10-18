#include <stdio.h>
#include <stdlib.h>
#include <string.h>

//------------------------------------------------------------------------------
char *BashLine (char *CommandLine, char *Buffer, int LgBuffer)
{
  FILE *Output;

  Output = popen (CommandLine,"r");
  fgets  (Buffer,LgBuffer,Output);
  pclose (Output);

  return Buffer;
}

//------------------------------------------------------------------------------
void BashList (char *CommandLine,
		char *Buffer, int LgBuffer,
		void (*CallBack)(char *Buffer))
{
  FILE *Output;

  Output = popen (CommandLine,"r");
  while (!feof(Output))
    {
      if (!fgets (Buffer,LgBuffer,Output)) continue;
      CallBack (Buffer);
    }
  pclose (Output);
}

