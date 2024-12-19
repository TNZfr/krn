#------------------------------------------------------------------------------------------------
LoadModule ()
{
    _Module=$KRN_LIB/Module.sh

    if [ -f $_Module ]
    then
	. $_Module

	_Overload=$KRN_LIB/Overload.sh
	[ -f $_Overload ] && . $_Overload
    else
	echo ""
	echo -e "\033[30;46m Mode $KRN_MODE \033[m : No module found for current mode."
	echo ""
	exit 1
    fi
}

#-------------------------------------------------------------------------------
_OverloadModule ()
{
    #
    # Calling parameter : Kernel Version (KRN_PVBuild)
    #
    return 0
}

#------------------------------------------------------------------------------------------------
ParseLinuxVersion ()
{
    $(linux-version-archbuild $1)
}

#------------------------------------------------------------------------------------------------
printh ()
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
    [ "${AD_Duree:0:1}" = "-" ] && return
    [ "${AD_Duree:0:1}" = "." ] && AD_Duree="0$AD_Duree"
    
    Seconde=$(echo $AD_Duree|cut -d. -f1)
    Milli=$(  echo $AD_Duree|cut -d. -f2)
    Milli=${Milli:0:3}

    (( Jour   = $Seconde / 86400 )) ; (( Seconde = $Seconde % 86400 ))
    (( Heure  = $Seconde /  3600 )) ; (( Seconde = $Seconde %  3600 ))
    (( Minute = $Seconde /    60 )) ; (( Seconde = $Seconde %    60 ))

    [ $Jour   -gt 0 ] && printf "${Jour}j ${Heure}h ${Minute}m ${Seconde}s.$Milli\n" && return
    [ $Heure  -gt 0 ] && printf "${Heure}h ${Minute}m ${Seconde}s.$Milli\n"          && return
    [ $Minute -gt 0 ] && printf "${Minute}m ${Seconde}s.$Milli\n"                    && return
    echo "${Seconde}s.$Milli"
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
	return 1
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
	return 2
    fi

    if [ ! -f $KRNSB_PRIV ] || [ ! -f $KRNSB_DER ] || [ ! -f $KRNSB_PEM ]
    then
	echo ""
	echo "Missing signing file(s)" 
	printf " - $KRNSB_PRIV : %s\n" "$([ -f $KRNSB_PRIV ] && printf "\033[32mFound.\033[m" || printf "\033[31mNOT FOUND.\033[m")"
	printf " - $KRNSB_DER  : %s\n" "$([ -f $KRNSB_DER ]  && printf "\033[32mFound.\033[m" || printf "\033[31mNOT FOUND.\033[m")"
	printf " - $KRNSB_PEM  : %s\n" "$([ -f $KRNSB_PEM ]  && printf "\033[32mFound.\033[m" || printf "\033[31mNOT FOUND.\033[m")"
	echo ""
	return 3
    fi
    return 0
}

#-------------------------------------------------------------------------------
_RefreshInstalledKernel ()
{
    _ModuleList=$KRN_RCDIR/.ModuleList
    _ModuleDir=""
    [ -d /usr/lib/modules ] && _ModuleDir=/usr/lib/modules
    [ -d /lib/modules     ] && _ModuleDir=/lib/modules
    [ "$_ModuleDir" = ""  ] && return

    if   [ ! -f $_ModuleList ]
    then
	# Creation 
	touch $_ModuleList
	
    elif [ $_ModuleDir -ot $_ModuleList ]
    then
	# no update needed
	return
    fi

    > $_ModuleList
    for _ModuleVersion in $(ls -1 $_ModuleDir)
    do
	ParseLinuxVersion $_ModuleVersion
	
	# Format : Version;NomModule;FullPath;Directory Size
	_Size=$(echo $(du -hs $_ModuleDir/$_ModuleVersion|tr ['\t'] [' ']|cut -d' ' -f1))
	echo "$KRN_LVBuild,$_ModuleVersion,$_ModuleDir/$_ModuleVersion,$_Size" >> $_ModuleList
    done
}

#-------------------------------------------------------------------------------
ListInstalledKernel ()
{
    _RefreshInstalledKernel
    _ModuleList=$KRN_RCDIR/.ModuleList
   
    echo ""
    echo "Installed kernel(s)"
    echo "-------------------"
    cat $_ModuleList|linux-version-sort|while read _Enreg
    do
	_ModuleDir=$( echo $_Enreg|cut -d',' -f2)
	_ModuleSize=$(echo $_Enreg|cut -d',' -f4)
	
	printf "%-22s \033[36mModule directory size\033[m %s\n" \
	       $_ModuleDir $_ModuleSize
    done
    echo ""
}

#-------------------------------------------------------------------------------
_RefreshWorkspaceList()
{
    # List generation only if modified
    [ ! -d $KRN_WORKSPACE ] && return
    [ "$(ls -1atr $KRN_WORKSPACE|tail -1)" = "$KRN_WORKSPACE/.CompletionList" ] && return

    CurrentDir=$PWD
    cd $KRN_WORKSPACE
    
    > .CompletionList

    _ListeFichier=$(ls -1|grep -v "Compil-"; find -name "Compil-*")
    [ "$_ListeFichier" != "" ] && for _Fichier in $_ListeFichier
    do
	# suppression du ./ au debut en retour du find
	[ ${_Fichier:0:2} = "./" ] && _Fichier=${_Fichier:2}
	
	_TypeObjet=""
	[ $_Fichier != ${_Fichier%.deb} ]         && _TypeObjet="deb,\033[32mDebian package (deb)\033[m"
	[ $_Fichier != ${_Fichier%.rpm} ]         && _TypeObjet="rpm,\033[32mRedhat package (rpm)\033[m"
	[ $_Fichier != ${_Fichier%.krn.tar.zst} ] && _TypeObjet="pkg,\033[36mKRN package (krn.tar.zst)\033[m"
	[ $_Fichier != ${_Fichier%.pkg.tar.zst} ] && _TypeObjet="pkg,\033[36mArch package (pkg.tar.zst)\033[m"
	[ $_Fichier != ${_Fichier%.tar.??} ]      && _TypeObjet="tar,Kernel source archive ($(echo $_Fichier|rev|cut -c1,2|rev))"

	_Version=""
	case $_Fichier in
	    
	    # Package Redhat (rpm)
	    # --------------------
	    kernel-headers-*_rc*.rpm)	                  _Version=$(echo $_Fichier|cut -d- -f3|cut -d_ -f1)-$(echo $_Fichier|cut -d- -f3|cut -d_ -f2) ;;
	    kernel-devel-*_rc*.rpm)	                  _Version=$(echo $_Fichier|cut -d- -f3|cut -d_ -f1)-$(echo $_Fichier|cut -d- -f3|cut -d_ -f2) ;;
	    kernel-*_rc*.rpm)		                  _Version=$(echo $_Fichier|cut -d- -f2|cut -d_ -f1)-$(echo $_Fichier|cut -d- -f2|cut -d_ -f2) ;;
	    
 	    kernel-headers-*.rpm)	                  _Version=$(echo $_Fichier|cut -d- -f3|cut -d_ -f1) ;;
	    kernel-devel-*.rpm)	                          _Version=$(echo $_Fichier|cut -d- -f3|cut -d_ -f1) ;;
	    kernel-*.rpm)		                  _Version=$(echo $_Fichier|cut -d- -f2|cut -d_ -f1) ;;
    
	    # Package Debian (deb)
	    # --------------------
	    linux-libc-dev_*-rc*-krn-*.deb)               _Version=$(echo $_Fichier|cut -d_ -f2|cut -d- -f1,2) ;;
	    linux-*-rc*-krn-*.deb) 	                  _Version=$(echo $_Fichier|cut -d- -f3,4)             ;;
	    
	    linux-libc-dev_*-krn-*.deb)                   _Version=$(echo $_Fichier|cut -d_ -f2|cut -d- -f1)   ;;
	    linux-*-krn-*.deb)                            _Version=$(echo $_Fichier|cut -d- -f3)               ;;

	    linux-image-unsigned-*-*rc*.deb)              _Version=$(echo $_Fichier|cut -d- -f4)-$(echo $_Fichier|cut -d- -f5|cut -c7-) ;;
	    linux-headers-*-*rc*_all.deb)                 _Version=$(echo $_Fichier|cut -d- -f3)-$(echo $_Fichier|cut -d- -f4|cut -c7-|cut -d_ -f1) ;;
	    linux-*-*-*rc*.deb)		                  _Version=$(echo $_Fichier|cut -d- -f3)-$(echo $_Fichier|cut -d- -f4|cut -c7-) ;;

	    linux-image-unsigned-*-*.deb)                 _Version=$(echo $_Fichier|cut -d- -f4) ;;
	    linux-*-*-*.deb)                              _Version=$(echo $_Fichier|cut -d- -f3) ;;

	    # Package Arch (pkg.tar.zst)
	    # --------------------------
	    linux-upstream-api-headers-*_rc*.pkg.tar.zst) _Version=$(echo $_Fichier|cut -d- -f5|cut -d_ -f1)-$(echo $_Fichier|cut -d_ -f2) ;;
	    linux-upstream-headers-*_rc*.pkg.tar.zst)     _Version=$(echo $_Fichier|cut -d- -f4|cut -d_ -f1)-$(echo $_Fichier|cut -d_ -f2) ;;
	    linux-upstream-*_rc*.pkg.tar.zst)             _Version=$(echo $_Fichier|cut -d- -f3|cut -d_ -f1)-$(echo $_Fichier|cut -d_ -f2) ;;

	    linux-upstream-api-headers-*.pkg.tar.zst)     _Version=$(echo $_Fichier|cut -d- -f5|cut -d_ -f1) ;;
	    linux-upstream-headers-*.pkg.tar.zst)         _Version=$(echo $_Fichier|cut -d- -f4|cut -d_ -f1) ;;
	    linux-upstream-*.pkg.tar.zst)                 _Version=$(echo $_Fichier|cut -d- -f3|cut -d_ -f1) ;;

	    # Package KRN (pkg.tar.zst)
	    # --------------------------
	    linux-*.krn.tar.zst)                          _Version=$(echo $_Fichier|cut -d- -f2-); _Version=${_Version%.krn.tar.zst} ;;
	    
	    # Sources kernel
	    # --------------
	    linux-*.tar.??)	                          _Version=$(echo $_Fichier|cut -d- -f2-); _Version=${_Version%.tar.??}	;;

	    # Repertoire install ARCH Linux
	    # -----------------------------
	    ARCH-linux-*|GENTOO-linux-*)
		[ ! -d $_Fichier ] && continue
		
		_TypeObjet="arc,\033[36mDirectory $_Fichier\033[m"
		_Version=$(echo $_Fichier|cut -d- -f3-)
		;;
	    
	    # Repertoire de build
	    # -------------------
	    *Compil-*)
		[ ! -d $_Fichier ] && continue
		
		if [ ${_Fichier:0:4} = "ckc-" ]
		then
		    RepCustom=$(dirname  ${_Fichier%/})
		    RepCompil=$(echo $_Fichier|cut -d/ -f2)
		    _TypeObjet="dir,\033[33mCompilation directory \033[35m$RepCustom\033[33m/$RepCompil"
		else
		    _TypeObjet="dir,\033[33mCompilation directory ${_Fichier%/}"
		fi
		
		cd $_Fichier
		
		_SourceDir=$(ls -1d linux-*/ 2>/dev/null)
		if [ "$_SourceDir" = "" ]
		then
		    cd ..
		    _Version=Unknown
		else
		    cd $_SourceDir
		    _Version=$(make kernelversion 2>/dev/null)
		fi
		cd $KRN_WORKSPACE
		;;

	    # Configuration custom
	    # --------------------
	    config-*-*)
		[ "$(echo $_Fichier|grep rc)" = "" ] && _Field="2" || _Field="2,3"
		_Version=$(echo $_Fichier|cut -d'-' -f$_Field)
		_TypeObjet="cfg,Kernel Configuration \033[34m$_Fichier\033[m"
		;;

	    # Noyaux custom
	    # -------------
	    ckc-*-*)
		[ "$(echo $_Fichier|grep rc)" = "" ] && _Field="2" || _Field="2,3"
		_Version=$(echo  $_Fichier|cut -d'-' -f$_Field)
		_Contenu=$(ls -1 $_Fichier 2>/dev/null)
		if   [ "${_Contenu:0:11}" = "ARCH-linux-" ];           then _TypeObjet="ckc,\033[mDirectory $_Contenu\033[m Custom \033[35m$_Fichier\033[m"
		elif [ "${_Contenu:0:13}" = "GENTOO-linux-" ];         then _TypeObjet="ckc,\033[mDirectory $_Contenu\033[m Custom \033[35m$_Fichier\033[m"
		elif [ "$(echo $_Contenu|grep .deb)" != "" ];          then _TypeObjet="ckc,\033[32mDebian package (deb)\033[m Custom \033[35m$_Fichier\033[m"
		elif [ "$(echo $_Contenu|grep .rpm)" != "" ];          then _TypeObjet="ckc,\033[32mRedhat package (rpm)\033[m Custom \033[35m$_Fichier\033[m"
		elif [ "$(echo $_Contenu|grep .krn.tar.zst)" != "" ];  then _TypeObjet="ckc,\033[36mKRN package (krn.tar.zst)\033[m Custom \033[35m$_Fichier\033[m"
		elif [ "$(echo $_Contenu|grep .pkg.tar.zst)" != "" ];  then _TypeObjet="ckc,\033[36mArch package (pkg.tar.zst)\033[m Custom \033[35m$_Fichier\033[m"
		else _TypeObjet="ckc,\033[31mEmpty\033[m Custom \033[35m$_Fichier\033[m"
		fi
		;;

	    # Fichiers inconnus
	    # -----------------
	    *) continue ;;
	esac

	# Enregistrement : Version,Type,LibelleType,NomObjet
	ParseLinuxVersion $_Version
	printf "$KRN_LVBuild,$_TypeObjet,$_Fichier\n" >> .CompletionList
    done
    cd $CurrentDir
}

#-------------------------------------------------------------------------------
_GetDevShmFreeMB ()
{
    _FreeMB=$(echo $(df -m /dev/shm|grep /dev/shm)|cut -d' ' -f4)
    [ "$_FreeMB" = "" ] && echo 0 || echo $_FreeMB
}

#-------------------------------------------------------------------------------
_GetDirectoryFreeMB ()
{
    _FreeMB=$(echo $(df -m $1|tail -1)|cut -d' ' -f4)
    [ "$_FreeMB" = "" ] && echo 0 || echo $_FreeMB
}

#-------------------------------------------------------------------------------
_CreateCompileDirectory ()
{
    TmpDir=$PWD/Compil-$$
    if [ $KRN_MINTMPFS != Unset ] && [ $(_GetDevShmFreeMB) -gt $KRN_MINTMPFS ]
    then
	FinalDir=/dev/shm/Compil-$$
	
	printh "Build temporary workspace on $FinalDir (tmpfs)"
	mkdir $FinalDir
	ln -s $FinalDir $TmpDir
    else
	FinalDir=$TmpDir
	
	printh "Build temporary workspace : $TmpDir"
	mkdir -p $TmpDir
    fi
}

#-------------------------------------------------------------------------------
_CleanTempDirectory ()
{
    _TempDirectory=$1

    if [ "$(ls $_TempDirectory/* 2>/dev/null)" != "" ]
    then
	for Object in $_TempDirectory/*
	do
	    [ -L $Object ] && rm -rf $(readlink -f $Object)
	done
    fi
    rm -rf $_TempDirectory/*
}

#-------------------------------------------------------------------------------
_RemoveTempDirectory ()
{
    _TempDirectory=$1
    
    _CleanTempDirectory $_TempDirectory
    rm -rf              $_TempDirectory
}
