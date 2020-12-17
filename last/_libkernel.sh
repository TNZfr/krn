#------------------------------------------------------------------------------------------------
function printh
{
    echo "$(date +%d/%m/%Y-%Hh%Mm%Ss) : $*"
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

    DebutMilli=$(echo $Debut|cut -d. -f2|cut -c1-3)
    while [ ${DebutMilli:0:1} = "0" ]; do DebutMilli=${DebutMilli:1}; done

    FinMilli=$(echo $Fin|cut -d. -f2|cut -c1-3)
    while [ ${FinMilli:0:1} = "0" ]; do FinMilli=${FinMilli:1}; done
    
    (( Seconde = $(echo $Fin|cut -d. -f1) - $(echo $Debut|cut -d. -f1) ))
    (( Milli   = FinMilli - DebutMilli ))
    if [ $Milli -lt 0 ]
    then
	(( Seconde -= 1 ))
	(( Milli += 1000 ))
    fi

    Milli=$(printf "%03d" $Milli)
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
    [ "$(env|grep ^${_NomVariable}=)" != "" ] && return

    # Non intialisee 
    if [ -f $HOME/.krn/bashrc ]
    then
	. $HOME/.krn/bashrc
	[ "$(env|grep ^${_NomVariable}=)" != "" ] && return
    fi

    # La variable n'existe pas, saisie utilisateur
    echo ""
    echo $_Explication
    read -ep "Valeur pour $_NomVariable : " _Valeur 0>&1
    
    mkdir -p $HOME/.krn
    echo "export $_NomVariable=$_Valeur" >> $HOME/.krn/bashrc
    . $HOME/.krn/bashrc

    case $_Type in
	dir)
	    _Valeur=$(eval echo $_Valeur)
	    if [ ! -d $_Valeur ]
	    then
		mkdir -p $_Valeur
	    fi
	    ;;
    esac
}

#------------------------------------------------------------------------------------------------
SortVersion ()
{
    _NumList=""
    for _Version in $(echo $*)
    do
	_Version=$(echo $_Version|sed 's/-/./g')
	
	_Champ1=$(echo $_Version|cut -d. -f1)
	[ ${#_Champ1} -eq 1 ] && _Champ1="0$_Champ1"

	_Champ2=$(echo $_Version|cut -d. -f2)
	[ ${#_Champ2} -eq 1 ] && _Champ2="0$_Champ2"

	_Champ3=$(echo $_Version|cut -d. -f3)
	while [ ${#_Champ3} -lt 3 ]; do _Champ3="0$_Champ3"; done
	[ ${_Champ3:0:1} != "r" ] && _Champ3="z$_Champ3"
	
	_NumList="$_NumList $_Champ1$_Champ2$_Champ3"
    done
    
    for _Version in $(echo $_NumList|sed 's/ /\n/g'|sort)
    do
	_Champ1=$(echo $_Version|cut -c1,2)
	[ ${_Champ1:0:1} = "0" ] && _Champ1=${_Champ1:1}

	_Champ2=$(echo $_Version|cut -c3,4)
	[ ${_Champ2:0:1} = "0" ] && _Champ2=${_Champ2:1}

	_Champ3=$(echo $_Version|cut -c5-)
	[ "$_Champ3" = "" ]       && echo $_Champ1.$_Champ2          && continue
	[ "$_Champ3" = "z000" ]   && echo $_Champ1.$_Champ2          && continue
	[ ${_Champ3:0:2} = "rc" ] && echo $_Champ1.$_Champ2-$_Champ3 && continue

	_Champ3=${_Champ3:1}
	[ ${_Champ3:0:1} = "0" ]  && _Champ3=${_Champ3:1}
	[ ${_Champ3:0:1} = "0" ]  && _Champ3=${_Champ3:1}

	echo $_Champ1.$_Champ2.$_Champ3
    done
}
