#ifndef _CSV_ParseFile_H
#define _CSV_ParseFile_H

typedef struct
{
  unsigned int NbField;
  char       **Field;
} CSVRECORD;

typedef struct
{
  unsigned int NbRecord;
  CSVRECORD   *Record;
  char        *Data;
} CSVFILE;

void CSV_ParseFile (CSVFILE *CSV_File, char *CSV_Filename, char FieldDelimiter);
void CSV_FreeFile  (CSVFILE *CSV_File);

#endif
