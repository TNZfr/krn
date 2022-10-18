int krn_Compile(int NbArg, char**Arg);
int krn_CompilInstall(int NbArg, char**Arg);
int krn_CompileSign(int NbArg, char**Arg);
int krn_CompilSignInstall(int NbArg, char**Arg);
int krn_Configure(int NbArg, char**Arg);
int krn_ChangeLog(int NbArg, char**Arg);
int krn_GetKernel(int NbArg, char**Arg);
int krn_GetSource(int NbArg, char**Arg);
int krn_InstallKernel(int NbArg, char**Arg);
int krn_InstallSignKernel(int NbArg, char**Arg);
int krn_ListKernel(int NbArg, char**Arg);
int krn_Purge(int NbArg, char**Arg);
int krn_RemoveKernel(int NbArg, char**Arg);
int krn_SaveLog(int NbArg, char**Arg);
int krn_SetConfig(int NbArg, char**Arg);
int krn_SearchKernel(int NbArg, char**Arg);
int krn_SignKernel(int NbArg, char**Arg);
int krn_VerifyKernel(int NbArg, char**Arg);

typedef struct
{
  char *Libelle;
  int  (*Fonction)(int NbArg, char**Arg);
  
} KRNCMD;

// ATTENTION : Garder la liste triee
int NbCommandeKRN = 33;
KRNCMD CommandeKRN[] =
  {
   "cc"               ,krn_Compile,
   "cci"              ,krn_CompilInstall,
   "ccs"              ,krn_CompileSign,
   "ccsi"             ,krn_CompilSignInstall,
   "cf"               ,krn_Configure,
   "changelog"        ,krn_ChangeLog,
   "cl"               ,krn_ChangeLog,
   "compile"          ,krn_Compile,
   "compilesign"      ,krn_CompileSign,
   "compilinstall"    ,krn_CompilInstall,
   "compilsigninstall",krn_CompilSignInstall,
   "configure"        ,krn_Configure,
   "get"              ,krn_GetKernel,
   "getsource"        ,krn_GetSource,
   "gk"               ,krn_GetKernel,
   "gs"               ,krn_GetSource,
   "install"          ,krn_InstallKernel,
   "installsign"      ,krn_InstallSignKernel,
   "is"               ,krn_InstallSignKernel,
   "list"             ,krn_ListKernel,
   "ls"               ,krn_ListKernel,
   "purge"            ,krn_Purge,
   "remove"           ,krn_RemoveKernel,
   "savelog"          ,krn_SaveLog,
   "sc"               ,krn_SetConfig,
   "se"               ,krn_SearchKernel,
   "search"           ,krn_SearchKernel,
   "setconfig"        ,krn_SetConfig,
   "sign"             ,krn_SignKernel,
   "sk"               ,krn_SignKernel,
   "sl"               ,krn_SaveLog,
   "verifykernel"     ,krn_VerifyKernel,
   "vk"               ,krn_VerifyKernel
  };
