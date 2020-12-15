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
    case $DebutMilli in
	00*) DebutMilli=$(echo $DebutMilli|cut -c3  ) ;;
	0*)  DebutMilli=$(echo $DebutMilli|cut -c2-3) ;;
    esac

    FinMilli=$(  echo $Fin  |cut -d. -f2|cut -c1-3)
    case $FinMilli in
	00*) FinMilli=$(echo $FinMilli|cut -c3  ) ;;
	0*)  FinMilli=$(echo $FinMilli|cut -c2-3) ;;
    esac
    
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

