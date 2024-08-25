
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main (int NbArg, char **Arg)
{
  char *Digit1, *Digit2, *Digit3, *RC, *Label, *EndString;
  char LV_Arch[32], LV_Build[32], LV_Package[32], LV_Ckc[256];
  
  if (NbArg < 2)
    {
      printf ("\n");
      printf ("Syntax : %s Version\n",Arg[0]);
      printf ("\n");
      printf ("\tVersion : Linux version to be parsed\n");
      printf ("\n");
      return 1;
    }

  // Custom kernel config
  if (memcmp (Arg[1],"ckc-",4) == 0)
       Digit1 = &Arg[1][4];
  else Digit1 =  Arg[1];
  
  Digit2 = strchr(Digit1,'.');
  if (!Digit2)
    {
      printf ("echo ERROR parsing %s\n", Arg[1]);
      return 1;
    }
  *Digit2 = '\0';
  Digit2 ++;

  Digit3 = "";
  EndString = strchr(Digit2,'.');
  if (EndString)
    {
      Digit3  = EndString;
      *Digit3 = '\0';
      Digit3 ++;
      EndString = Digit3;
    }
  else EndString = Digit2;
  
  Label = NULL;
  RC  = strchr(EndString,'-');
  if (RC)
    {
      *RC = '\0';
      RC++;
      if (memcmp(RC,"rc",2) != 0)
	{
	  // CKC label
	  Label = RC;
	  RC    = NULL;
	}
      else
	{
	  char *Minus = strchr (RC,'-');
	  if (Minus)
	    {
	      *Minus = '\0';
	      Label  = &Minus[1];
	    }	  
	}
    }

  if (Digit3[0] == '0') Digit3 = "";

  if      ( Digit3[0] &&  RC) sprintf (LV_Arch,"%s.%s.%s-%s", Digit1, Digit2, Digit3, RC);
  else if ( Digit3[0] && !RC) sprintf (LV_Arch,"%s.%s.%s",    Digit1, Digit2, Digit3    );
  else if (!Digit3[0] &&  RC) sprintf (LV_Arch,"%s.%s-%s",    Digit1, Digit2, RC        );  
  else                        sprintf (LV_Arch,"%s.%s",       Digit1, Digit2            );

  if      ( Digit3[0] &&  RC) sprintf (LV_Build,"%s.%s.%s-%s", Digit1, Digit2, Digit3, RC);
  else if ( Digit3[0] && !RC) sprintf (LV_Build,"%s.%s.%s",    Digit1, Digit2, Digit3    );
  else if (!Digit3[0] &&  RC) sprintf (LV_Build,"%s.%s.0-%s",  Digit1, Digit2, RC        );  
  else                        sprintf (LV_Build,"%s.%s.0",     Digit1, Digit2            );

  if (!strcmp(getenv("KRN_MODE"),"REDHAT") || !strcmp(getenv("KRN_MODE"),"ARCH"))
    {
      if      ( Digit3[0] &&  RC) sprintf (LV_Package,"%s.%s.%s_%s", Digit1, Digit2, Digit3, RC);
      else if ( Digit3[0] && !RC) sprintf (LV_Package,"%s.%s.%s",    Digit1, Digit2, Digit3    );
      else if (!Digit3[0] &&  RC) sprintf (LV_Package,"%s.%s.0_%s",  Digit1, Digit2, RC        );  
      else                        sprintf (LV_Package,"%s.%s.0",     Digit1, Digit2            );
    }
  else strcpy (LV_Package, LV_Build);

  if (Label)
       sprintf (LV_Ckc,"ckc-%s-%s", LV_Build, Label);
  else strcpy  (LV_Ckc,"normal_release");
  
  printf ("export KRN_LVArch=%s \nexport KRN_LVBuild=%s\nexport KRN_LVPackage=%s\nexport KRN_LVCkc=%s\n",
	  LV_Arch, LV_Build, LV_Package, LV_Ckc);
}
