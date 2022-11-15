#------------------------------------------------------------------------------------------------
function printh
{
    printf "$(date +%d/%m/%Y-%Hh%Mm%Ss) : $*\n"
}


#------------------------------------------------------------------------------------------------
TopHorloge ()
{
    date +%s.%N
}

#------------------------------------------------------------------------------------------------
AfficheDuree ()
{
    # Parametres au format SECONDE.NANO (date +%s.%N)
    Debut=$1
    Fin=$2

    AD_Duree=$(echo "scale=6; $Fin - $Debut"|bc)
    [ "${AD_Duree:0:1}" = "." ] && AD_Duree="0$AD_Duree"
    
    Seconde=$(echo $AD_Duree|cut -d. -f1)
    Milli=$(  echo $AD_Duree|cut -d. -f2)
    Milli=${Milli:0:3}

    (( Jour   = $Seconde / 86400 )) ; (( Seconde = $Seconde % 86400 ))
    (( Heure  = $Seconde /  3600 )) ; (( Seconde = $Seconde %  3600 ))
    (( Minute = $Seconde /    60 )) ; (( Seconde = $Seconde %    60 ))

    [ $Jour   -gt 0 ] && printf "${Jour}j ${Heure}h ${Minute}m ${Seconde}s.$Milli\n" && return
    [ $Heure  -gt 0 ] && printf "${Heure}h ${Minute}m ${Seconde}s.$Milli\n" && return
    [ $Minute -gt 0 ] && printf "${Minute}m ${Seconde}s.$Milli\n" && return
    echo "${Seconde}s.$Milli"
}

#------------------------------------------------------------------------------------------------
InitVariable ()
{

    _NomVariable=$1
    _Type=$2
    _Explication=$(echo $*|cut -d' ' -f3-)

    # La variable existe
    if [ "$(env|grep ^KRN_${_NomVariable}=)" != "" ]
    then
	if [ $_Type = dir ]
	then
	    _Repertoire=$(env|grep ^KRN_${_NomVariable}=|cut -d= -f2)
	    [ ! -d $_Repertoire ] && mkdir -p $_Repertoire && echo "$_Repertoire (re)created."
	fi
	return
    fi

    # Non intialisee 
    if [ -f $HOME/.krn/bashrc ]
    then
	. $HOME/.krn/bashrc
	if [ "$(env|grep ^KRN_${_NomVariable}=)" != "" ]
	then
	    if [ $_Type = dir ]
	    then
		_Repertoire=$(env|grep ^KRN_${_NomVariable}=|cut -d= -f2)
		[ ! -d $_Repertoire ] && mkdir -p $_Repertoire && echo "$_Repertoire (re)created."
	    fi
	    return
	fi
    fi

    # La variable n'existe pas, saisie utilisateur
    echo ""
    echo $_Explication
    read -ep "Value for KRN_$_NomVariable : " _Valeur 0>&1
    
    case $_Type in
	dir)
	    _Valeur=$(eval echo $_Valeur)
	    [ ${_Valeur:0:1} != "/" ] && _Valeur=$PWD/$_Valeur
	    
	    if [ ! -d $_Valeur ]
	    then
		mkdir -p $_Valeur
		echo "$_Valeur created."
	    fi
	    ;;
    esac

    mkdir -p $HOME/.krn
    export KRN_$_NomVariable=$_Valeur
    env | grep ^KRN_ | grep -v ^KRN_EXE= | while read Line; do echo export $Line;done > $HOME/.krn/bashrc
    
    . $HOME/.krn/bashrc
}

#------------------------------------------------------------------------------------------------
CreateGrubenv ()
{
    Version=$1

    
}

#------------------------------------------------------------------------------------------------
VerifySigningConditions ()
{
    # tester le repertoire du certificat
    NbVar=$(env|grep ^KRNSB_|wc -l)
    if [ $NbVar -lt 4 ]
    then
	echo ""
	echo "Missing signing parameters (Cf krn Configure)" 
	echo ""
	exit 1
    fi

    if [ -z "$KRNSB_PRIV" ] || [ -z "$KRNSB_DER" ] || [ -z "$KRNSB_PEM" ]
    then
	echo ""
	echo "Signing parameter(s) not defined" 
	echo ""
	printf " - \033[34mPrivate Key\033[m : %s\n" $(env|grep ^KRNSB_PRIV)
	printf " - \033[34mPulbic Key\033[m  : %s\n" $(env|grep ^KRNSB_DER)
	printf " - \033[34mCertificat\033[m  : %s\n" $(env|grep ^KRNSB_PEM)
	echo ""
	exit 1
    fi

    if [ ! -f $KRNSB_PRIV ] || [ ! -f $KRNSB_DER ] || [ ! -f $KRNSB_PEM ]
    then
	echo ""
	echo "Missing signing file(s)" 
	printf " - $KRNSB_PRIV : %s\n" "$([ -f $KRNSB_PRIV ] && printf "\033[32mFound.\033[m" || printf "\033[31mNOT FOUND.\033[m")"
	printf " - $KRNSB_DER  : %s\n" "$([ -f $KRNSB_DER ]  && printf "\033[32mFound.\033[m" || printf "\033[31mNOT FOUND.\033[m")"
	printf " - $KRNSB_PEM  : %s\n" "$([ -f $KRNSB_PEM ]  && printf "\033[32mFound.\033[m" || printf "\033[31mNOT FOUND.\033[m")"
	echo ""
	exit 1
    fi
}

#-------------------------------------------------------------------------------
GetInstalledKernel ()
{
    _ModulesDir=""
    [ -d /usr/lib/modules ] && _ModulesDir=/usr/lib/modules
    [ -d /lib/modules ]     && _ModulesDir=/lib/modules
    [ "$_ModulesDir" = "" ] && return

    for _ModulesVersion in $(ls -1 $_ModulesDir)
    do
	if [ "$(echo $_ModulesVersion|grep rc)" = "" ]
	then
	    _Version=$(echo $_ModulesVersion|cut -d- -f1)
	else
	    _Version=$(echo $_ModulesVersion|cut -d- -f1,2)
	fi
	
	# Format : Version;NomModule;FullPath
	echo "$_Version,$_ModulesVersion,$_ModulesDir/$_ModulesVersion"
    done
}

#-------------------------------------------------------------------------------
ListInstalledKernel ()
{
    
    echo ""
    echo "Installed kernel(s)"
    echo "-------------------"
    for _Enreg in $(GetInstalledKernel|linux-version sort)
    do
	_ModuleDir=$(echo $_Enreg|cut -d',' -f3)
	printf "%-20s \033[36mModule directory size\033[m %s\n"    \
	       $(basename $_ModuleDir)                              \
	       $(du -hs   $_ModuleDir|tr ['\t'] [' ']|cut -d' ' -f1)
    done
    echo ""
}

#-------------------------------------------------------------------------------
GetWorkspaceList()
{
    CurrentDir=$PWD
    cd $KRN_WORKSPACE
    
    _ListeFichier=$(ls -1)
    [ "$_ListeFichier" != "" ] && for _Fichier in $_ListeFichier
    do
	_TypeObjet=""
	[ $_Fichier != ${_Fichier%.deb} ]    && _TypeObjet="deb,\033[32mDebian package (deb)\033[m"
	[ $_Fichier != ${_Fichier%.rpm} ]    && _TypeObjet="rpm,\033[32mRedhat package (rpm)\033[m"
	[ $_Fichier != ${_Fichier%.tar.??} ] && _TypeObjet="tar,Kernel source archive ($(echo $_Fichier|rev|cut -c1,2|rev))"

	_Version=""
	case $_Fichier in
	    
	    # Package Redhat (rpm)
	    # --------------------
	    kernel-headers-*.rpm)	     _Version=$(echo $_Fichier|cut -d- -f3|cut -d_ -f1) ;;
	    kernel-*.rpm)		     _Version=$(echo $_Fichier|cut -d- -f2|cut -d_ -f1) ;;
    
	    # Package Debian (deb)
	    # --------------------
	    linux-libc-dev_*-rc*-krn-*.deb)  _Version=$(echo $_Fichier|cut -d_ -f2|cut -d- -f1,2) ;;
	    linux-*-rc*-krn-*.deb) 	     _Version=$(echo $_Fichier|cut -d- -f3,4)             ;;
	    
	    linux-libc-dev_*-krn-*.deb)      _Version=$(echo $_Fichier|cut -d_ -f2|cut -d- -f1)   ;;
	    linux-*-krn-*.deb)               _Version=$(echo $_Fichier|cut -d- -f3)               ;;

	    linux-image-unsigned-*-*rc*.deb) _Version=$(echo $_Fichier|cut -d- -f4)-$(echo $_Fichier|cut -d- -f5|cut -c7-) ;;
	    linux-headers-*-*rc*_all.deb)    _Version=$(echo $_Fichier|cut -d- -f3)-$(echo $_Fichier|cut -d- -f4|cut -c7-|cut -d_ -f1) ;;
	    linux-*-*-*rc*.deb)		     _Version=$(echo $_Fichier|cut -d- -f3)-$(echo $_Fichier|cut -d- -f4|cut -c7-) ;;

	    linux-image-unsigned-*-*.deb)    _Version=$(echo $_Fichier|cut -d- -f4) ;;
	    linux-*-*-*.deb)                 _Version=$(echo $_Fichier|cut -d- -f3) ;;

	    # Sources kernel
	    # --------------
	    linux-*.tar.??)	             _Version=$(echo $_Fichier|cut -d- -f2-); _Version=${_Version%.tar.??}	;;
	    
	    # Repertoire install ARCH Linux
	    # -----------------------------
	    ARCH-linux-*)
		[ ! -d $_Fichier ] && continue
		
		_TypeObjet="arc,\033[36mDirectory $_Fichier\033[m"
		_Version=$(echo $_Fichier|cut -d- -f3-)
		;;
	    
	    # Repertoire de build
	    # -------------------
	    Compil-*)
		[ ! -d $_Fichier ] && continue
		
		_TypeObjet="dir,\033[33mCompilation directory ${_Fichier%/}\033[m"
		cd $_Fichier
		
		_SourceDir=$(ls -1d linux-*/ 2>/dev/null)
		if [ "$_SourceDir" = "" ]
		then
		    cd ..
		    _Version=Unknown
		    continue
		fi
		cd $_SourceDir
		_Version=$(make kernelversion 2>/dev/null)
		cd $KRN_WORKSPACE
		;;

	    # Fichiers inconnus
	    # -----------------
	    *) continue ;;
	esac

	# Enregistrement : Version,Type,LibelleType,NomObjet
	printf "$_Version,$_TypeObjet,$_Fichier\n"
    done
    cd $CurrentDir
}

