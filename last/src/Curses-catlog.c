#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/time.h>

#include "CSV_ParseFile.h"

//------------------------------------------------------------------------------
char *CurrentDateTime (char *Buffer)
{
  time_t     NbSec    = time(NULL);
  struct tm *DateTime = localtime(&NbSec);

  sprintf (Buffer,"%d/%02d/%d %dh%02dm%02ds",
	   DateTime->tm_mday, DateTime->tm_mon + 1, DateTime->tm_year + 1900,
	   DateTime->tm_hour, DateTime->tm_min,     DateTime->tm_sec         );
  
  return Buffer;
}

//------------------------------------------------------------------------------
int LogRefreshed ()
{
  FILE *pDesc;
  char  Output [256];

  memset (Output,0,sizeof(Output));
  pDesc = popen("cd $KRNC_TMP; ls -1tr exec.log RefreshLog 2>/dev/null|tail -1","r");
  fgets  (Output,sizeof(Output),pDesc);
  pclose (pDesc);

  if (strncmp(Output,"RefreshLog",10) == 0) return 0;

  pclose(popen("touch $KRNC_TMP/RefreshLog 2>/dev/null","r"));
  return 1;
}

//------------------------------------------------------------------------------
void DSP_TailLog (int Row, int Col, int TailSize, int ForceRefresh)
{
  static CSVFILE LOG;

  char    DateTime [ 64]; 
  char    LogFile  [256];

  char *ErrorLog;
  FILE *ErrorDesc;

  
  // Header
  if (ForceRefresh)
    printf ("%c[%d;%dH------------------------------------------------------------------------------\n",
	    27,Row,Col);
  
  // Cursor positionning
  Row += 1;

  // Date Time
  printf ("%c[%d;%dH%c[30;46m %s %c[m  \n",
	  27,Row,Col,
	  27,CurrentDateTime (DateTime),27);

  // Error file manangement
  ErrorDesc = NULL;
  ErrorLog  = getenv("KRNC_ErrorLog");
  if (ErrorLog) ErrorDesc = fopen(ErrorLog,"r");
  if (ErrorDesc)
    {
      fclose (ErrorDesc);
      pclose (popen("cat $KRNC_ErrorLog","r"));
      return;
    }

  // Refresh management 
  if (ForceRefresh || LogRefreshed())
    {
      register int Start, Index;
      
      // Load log file
      sprintf (LogFile,"%s/exec.log",getenv("KRNC_TMP"));
      CSV_ParseFile (&LOG, LogFile, '\n');

      // Select reading index
      Start = LOG.NbRecord - TailSize;
      if (Start < 0) Start = 0;

      // Display file trailer 
      printf ("%c[0J",27);
      for (Index=Start; Index < LOG.NbRecord; Index ++) printf ("%s\n", LOG.Record[Index].Field[0]);
    }

  // Final cursor positionning
  Row += TailSize + 1;
  
  printf ("%c[%d;%dH",27,Row,Col);
  
  CSV_FreeFile (&LOG);
}
