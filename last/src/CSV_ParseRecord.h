#ifndef _CSV_ParseRecord_H
#define _CSV_ParseRecord_H

#define CSVPARSE_MAXRECLEN 2048 // define the max length for one record read from CSV file

typedef struct
{
  char **Field;
  int    MaxField;

} _CSVPARSE;

int CSV_ParseRecord (char *CSV_Filename, 
		     char  FieldDelimiter, 
		     int (*UseParsedRecord) (int    RecordNumber, 
					     int    NbField, 
					     char **Field,
					     void  *Param        ),
		     void *Param);

//------------------------------------------------------------------------------
// NB : UseParsedRecord function must return non-null value to continue on next 
//      record, otherwise the reading/parse loop will be stopped and 
//      CSV_ParseRecord will terminate after freeing memory and closing current 
//      file descriptor on CSV_Filename.
//------------------------------------------------------------------------------

#endif
