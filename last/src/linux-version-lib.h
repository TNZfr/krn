
typedef struct
{
  short Major;
  short Minor;
  short NotRC;  // RC=0, Normal=1
  short Release;

  char *String;
} LNXVER;

#define FALSE 0
#define TRUE  1

void LV_Parse (LNXVER *LV, char *String); 
