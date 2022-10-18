#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <sys/stat.h>

#include "CSV_ParseFile.h"

//------------------------------------------------------------------------------
int CSV_CountRecord (char *Data)
{
  char  FieldDelimiter;
  int   NbRecord       = 1;
  char *DelimiterPtr   = Data;

  FieldDelimiter = (strchr(Data,'\r')) ? '\r' : '\n';

  DelimiterPtr = strchr(DelimiterPtr, FieldDelimiter);
  while (DelimiterPtr)
    {
      NbRecord     ++;
      DelimiterPtr ++;
      DelimiterPtr = strchr(DelimiterPtr, FieldDelimiter);
    }
  return NbRecord;
}

//------------------------------------------------------------------------------
int CSV_CountField (char *Record, char FieldDelimiter)
{
  int   NbField      = 1;
  char *DelimiterPtr = Record;

  DelimiterPtr = strchr(DelimiterPtr, FieldDelimiter);
  while (DelimiterPtr)
    {
      NbField      ++;
      DelimiterPtr ++;
      DelimiterPtr = strchr(DelimiterPtr, FieldDelimiter);
    }
  return NbField;
}

//------------------------------------------------------------------------------
char *CSV_GetNextRecord (char **ParsePtr)
{
  char *DelimiterPtr;
  char *ReturnedString = *ParsePtr;

  if (!ReturnedString) return 0;

  // DOS file format with \r\n
  DelimiterPtr = strchr (ReturnedString, '\r');
  if (DelimiterPtr)
    {
      DelimiterPtr [0] = '\0';
      DelimiterPtr ++;
      if (DelimiterPtr[0] == '\n')
	{
	  DelimiterPtr [0] = '\0';
	  DelimiterPtr ++;
	}
    }
  else
    {      
      // UNIX file format with \n
      DelimiterPtr = strchr (ReturnedString, '\n');
      if (DelimiterPtr)
	{
	  DelimiterPtr [0] = '\0';
	  DelimiterPtr ++;
	}
    }
  *ParsePtr = DelimiterPtr;
  return ReturnedString;
}

//------------------------------------------------------------------------------
char *CSV_GetNextField (char **ParsePtr, char FieldDelimiter)
{
  char *DelimiterPtr;
  char *ReturnedString = *ParsePtr;

  if (!ReturnedString) return 0;

  DelimiterPtr = strchr (ReturnedString, FieldDelimiter);
  if (DelimiterPtr)
    {
      DelimiterPtr [0] = '\0';
      DelimiterPtr ++;
    }
  *ParsePtr = DelimiterPtr;
  return ReturnedString;
}

//------------------------------------------------------------------------------
void CSV_ParseFile (CSVFILE *CSV_File, char *CSV_Filename, char FieldDelimiter)
{
  struct stat FileInfo;
  char       *ParseRecord;
  char       *ParseField;

  FILE *Input;
  int   IdxRecord;
  int   IdxField;

  memset (CSV_File, 0, sizeof(CSVFILE));

  // Get the file size
  if (stat(CSV_Filename, &FileInfo) != 0)
    {
      printf ("CSV_ParseFile: Error getting size information for %s (errno=%d)\n",
	      CSV_Filename, errno);
      return;
    }

  // Empty file
  if (FileInfo.st_size == 0)
    {
      printf ("CSV_ParseFile: %s is empty. No parsing.\n", CSV_Filename);
      return;
    }

  // Allocate memory for entire file
  CSV_File->Data = (char *) malloc (FileInfo.st_size + 1);
  if (!CSV_File->Data)
    {
      printf ("CSV_ParseFile: Error allocating %d bytes of memory to load %s\n",
	      (int)FileInfo.st_size + 1, CSV_Filename);
      return;
    }

  // Load file in memory
  Input = fopen (CSV_Filename,"r");
  if (!Input)
    {
      printf ("CSV_ParseFile: Error opening %s for loading (errno=%d)\n",
	      CSV_Filename, errno);
      return;
    }
  fread  (CSV_File->Data, FileInfo.st_size, 1, Input);
  fclose (Input);
  CSV_File->Data[FileInfo.st_size] = '\0'; // to be sure to have a string terminator

  // Count records and allocate memory for pointers
  CSV_File->NbRecord = CSV_CountRecord  (CSV_File->Data);
  CSV_File->Record   = (CSVRECORD *) malloc (CSV_File->NbRecord * sizeof(CSVRECORD));
  if (!CSV_File->Record)
    {
      printf ("CSV_ParseFile: Error allocating %d record pointers for %s\n",
	      CSV_File->NbRecord, CSV_Filename);
      CSV_FreeFile (CSV_File);
      return;
    }

  // Parse the file
  IdxRecord   = 0;
  ParseRecord = CSV_File->Data;
  while (ParseRecord)
    {
      char *CurrentRecord;

      CurrentRecord = CSV_GetNextRecord (&ParseRecord);

      CSV_File->Record[IdxRecord].NbField = CSV_CountField   (CurrentRecord, FieldDelimiter);
      CSV_File->Record[IdxRecord].Field   = (char **) malloc (CSV_File->Record[IdxRecord].NbField * sizeof(char **));
      if (!CSV_File->Record[IdxRecord].Field)
	{
	  printf ("CSV_ParseFile: Error allocating %d field pointers for record #%d, record not parsed.\n",
		  CSV_File->Record[IdxRecord].NbField, IdxRecord + 1);
	  IdxRecord ++;
	  continue;
	}

      // Parse the record
      IdxField   = 0;
      ParseField = CurrentRecord;
      while (ParseField)
	{
	  CSV_File->Record[IdxRecord].Field[IdxField] = CSV_GetNextField (&ParseField, FieldDelimiter);
	  IdxField ++;
	}
      IdxRecord ++;
    }
}

//------------------------------------------------------------------------------
void CSV_FreeFile  (CSVFILE *CSV_File)
{
  register int Index;

  for (Index = 0; Index < CSV_File->NbRecord; Index ++)
    {
      free (CSV_File->Record[Index].Field);
    }
  free (CSV_File->Record);
  free (CSV_File->Data);
}
