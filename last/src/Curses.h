#ifndef _KRN_CURSES_H
#define _KRN_CURSES_H

#define TRUE  1
#define FALSE 0

typedef enum
{
  UNDEFINED,
  STATIC_BASH,
  STATIC,
  ELAPSED,
  BASH,
  STATUS,
  TAILLOG
} CELLTYPE;

typedef struct
{
  int TailSize;
} CELL_LOG;

typedef struct
{
  char *Buffer;
} CELL_STATIC;

typedef struct
{
  char *File;
  int   Size;
  char *Buffer;
  char  String[2][64];
} CELL_STATUS;

typedef struct
{
  char *Debut, *Fin;
  char *Buffer;
  char  Completed;
  char  String[2][64];
} CELL_ELAPSED;

typedef struct
{
  CELLTYPE Type;
  int      Row,Col;
  union
  {
    CELL_LOG     Log;
    CELL_STATIC  Static;
    CELL_STATIC  StaticBash;
    CELL_STATIC  Bash;
    CELL_STATUS  Status;
    CELL_ELAPSED Elapsed;
  } Union;
  
} CELL;

typedef struct
{
  int Current;
  
  int NbCell;
  int MaxCell;
  CELL *Cell;
} DISP;

void DSP_Init        (DISP *Display, int NbCell);
void DSP_Free        (DISP *Display);
void DSP_Refresh     (DISP *Display);
void DSP_FullRefresh (DISP *Display);

void DSP_RefreshCell (CELL *Cell, int Prev);
void DSP_Elapsed     (CELL_ELAPSED *Cell);
void DSP_Bash        (int Row, int Col, char *Commande, char *Parametre);
void DSP_TailLog     (int Row, int Col, int   TailSize, int   ForceRefresh);
#endif
