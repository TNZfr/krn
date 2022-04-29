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
SortFile ()
{
    _Fichier=$1

    [ ! -f $_Fichier ] && return
    cat $_Fichier|while read _Enreg
    do
	_Version=$(echo $_Enreg|cut -d' ' -f1)
	_Type=$(   echo $_Enreg|cut -d' ' -f2-)

	_Version=$(echo $_Version|sed 's/-/./g')
	
	_Champ1=$(echo $_Version|cut -d. -f1)
	[ ${#_Champ1} -eq 1 ] && _Champ1="0$_Champ1"

	_Champ2=$(echo $_Version|cut -d. -f2)
	[ ${#_Champ2} -eq 1 ] && _Champ2="0$_Champ2"

	_Champ3=$(echo $_Version|cut -d. -f3)
	while [ ${#_Champ3} -lt 3 ]; do _Champ3="0$_Champ3"; done
	[ $_Champ3 = "tar" ]      && _Champ3="000"
	[ ${_Champ3:0:1} != "r" ] && _Champ3="z$_Champ3"
	
	echo $_Champ1$_Champ2$_Champ3 $_Type >> ${_Fichier}.tmp
    done
    mv -f ${_Fichier}.tmp $_Fichier

    sort $_Fichier|while read _Enreg
    do
	_Version=$(echo $_Enreg|cut -d' ' -f1)
	_Type=$(   echo $_Enreg|cut -d' ' -f2-)
	
	_Champ1=$(echo $_Version|cut -c1,2)
	[ ${_Champ1:0:1} = "0" ] && _Champ1=${_Champ1:1}

	_Champ2=$(echo $_Version|cut -c3,4)
	[ ${_Champ2:0:1} = "0" ] && _Champ2=${_Champ2:1}

	_Champ3=$(echo $_Version|cut -c5-)
	[ "$_Champ3" = "" ]       && printf "%-10s $_Type\n" "$_Champ1.$_Champ2"          && continue
	[ "$_Champ3" = "z000" ]   && printf "%-10s $_Type\n" "$_Champ1.$_Champ2"          && continue
	[ ${_Champ3:0:2} = "rc" ] && printf "%-10s $_Type\n" "$_Champ1.$_Champ2-$_Champ3" && continue

	_Champ3=${_Champ3:1}
	while [ ${_Champ3:0:1} = "0" ]; do _Champ3=${_Champ3:1}; done

	printf "%-10s $_Type\n" "$_Champ1.$_Champ2.$_Champ3"
    done
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
