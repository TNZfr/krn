#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>

#include "CSV_ParseRecord.h"

//------------------------------------------------------------------------------
void CSV_CleanRecord (char *Record)
{
  char *Eol;

  // Remove end of line terminators
  Eol = strchr (Record,'\n');
  if (Eol) *Eol = 0;

  Eol = strchr (Record,'\r');
  if (Eol) *Eol = 0;
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
int CSV_ParseRecord (char *CSV_Filename, 
		     char  FieldDelimiter, 
		     int (*UseParsedRecord) (int    RecordNumber, 
					     int    NbField, 
					     char **Field,
					     void  *Param        ),
		     void *Param)
{
  char      Record [CSVPARSE_MAXRECLEN];
  _CSVPARSE ParseData;
  int       NbField;
  int       Index;

  char     *ParsePtr;

  int       RecordNumber = 0;
  FILE     *Input        = fopen (CSV_Filename,"r");

  if (!Input)
    {
      printf ("CSV_ParseRecord: Error opening %s for reading (errno=%d)\n",
	      CSV_Filename, errno);
      return 0;
    }

  memset (&ParseData, 0, sizeof(ParseData));

  while (!feof(Input))
    {
      if (!fgets(Record, sizeof(Record), Input)) continue;

      RecordNumber ++;
      CSV_CleanRecord (Record);

      // Field pointers managment
      // -----------------------
      NbField = CSV_CountField (Record, FieldDelimiter);
      if (NbField > ParseData.MaxField)
	{
	  if (ParseData.MaxField == 0)
	    {
	      ParseData.Field = (char **) malloc (NbField * sizeof(ParseData.Field));
	      if (!ParseData.Field)
		{
		  printf ("CSV_ParseRecord: File %s, Record #%d, Memory allocation error for %d field(s)\n", 
			  CSV_Filename, RecordNumber, NbField);
		  break;
		}
	      ParseData.MaxField = NbField;
	    }
	  else
	    {
	      char **NewPtr;

	      NewPtr = (char **) realloc ((void *)ParseData.Field, NbField * sizeof(ParseData.Field));
	      if (!NewPtr)
		{
		  printf ("CSV_ParseRecord: File %s, Record #%d, Memory re-allocation error (from %d to %d field(s))\n",
			  CSV_Filename, RecordNumber, ParseData.MaxField, NbField);
		  break;
		}
	      ParseData.Field    = NewPtr;
	      ParseData.MaxField = NbField;
	    }
	}
      memset (ParseData.Field, 0, ParseData.MaxField * sizeof(ParseData.Field[0]));

      // Parsing the record
      // ------------------
      Index    = 0;
      ParsePtr = Record;
      while (ParsePtr)
	{
	  ParseData.Field [Index] = CSV_GetNextField (&ParsePtr, FieldDelimiter);
	  Index ++;
	}

      // Execute the callback function
      // -----------------------------
      if (! UseParsedRecord (RecordNumber, NbField, ParseData.Field, Param)) break;
    }

  free   (ParseData.Field);
  fclose (Input);

  return RecordNumber;
}
