
//------------------------------------------------------------------------------
int krn_Compile           (int NbArg, char**Arg);
int krn_CompilInstall     (int NbArg, char**Arg);
int krn_CompileSign       (int NbArg, char**Arg);
int krn_CompilSignInstall (int NbArg, char**Arg);
int krn_Configure         (int NbArg, char**Arg);
int krn_ChangeLog         (int NbArg, char**Arg);
int krn_GetKernel         (int NbArg, char**Arg);
int krn_GetSource         (int NbArg, char**Arg);
int krn_InstallKernel     (int NbArg, char**Arg);
int krn_InstallSignKernel (int NbArg, char**Arg);
int krn_ListKernel        (int NbArg, char**Arg);
int krn_Purge             (int NbArg, char**Arg);
int krn_RemoveKernel      (int NbArg, char**Arg);
int krn_SaveLog           (int NbArg, char**Arg);
int krn_SetConfig         (int NbArg, char**Arg);
int krn_SearchKernel      (int NbArg, char**Arg);
int krn_SignKernel        (int NbArg, char**Arg);
int krn_VerifyKernel      (int NbArg, char**Arg);

//------------------------------------------------------------------------------
char *BashLine (char *CommandLine, char *Buffer, int LgBuffer);
void  BashList (char *CommandLine, char *Buffer, int LgBuffer, void (*CallBack)(char *Buffer));
