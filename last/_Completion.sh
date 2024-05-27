
_krn_completion_configfile ()
{
    local _Saisie=$1
    local _List=""

    KRN_WORKSPACE=$(krn _GetVar KRN_WORKSPACE)
    local _List=""
    krn _UpdateCompletion
    
    _List="$(grep ",cfg," $KRN_WORKSPACE/.CompletionList|cut -d',' -f4)"
    _List=$(echo $_List)

    COMPREPLY=($(compgen -W "$_List" "$_Saisie"))
}

_krn_completion ()
{
    if [ ${#COMP_WORDS[@]} -gt 2 ]
    then
	case $(echo ${COMP_WORDS[1]}|tr [:upper:] [:lower:]) in
	    watch|wa|detach|dt|curses|cu)
		local _Last=${COMP_WORDS[${#COMP_WORDS[@]}-1]}
		
		unset COMP_WORDS[1]
		COMP_WORDS=(${COMP_WORDS[*]})
		[ -z "$_Last" ] && COMP_WORDS+=("")
		_krn_completion
		;;
	esac
    fi
    
    case ${#COMP_WORDS[@]} in
	1|2)
	    KRN_EXE=$(krn _GetVar KRN_EXE)
	    COMPREPLY=($(grep -i "^${COMP_WORDS[1]}" $KRN_EXE/_Completion.csv|cut -d',' -f2|sort|uniq))
	    ;;

	*)
	    case $(echo ${COMP_WORDS[1]}|tr [:upper:] [:lower:]) in
		# Param = Installed Kernels
		remove|verifykernel|vk|sign|sk)
		    cur=${COMP_WORDS[${#COMP_WORDS[@]} - 1]}
		    _kernel_versions;
		    ;;

		# Param = Config file in workspace
		setconfig|sc)
		    if [ ${#COMP_WORDS[@]} -eq 3 ]
		    then
			_krn_completion_configfile ${COMP_WORDS[2]};
			COMPREPLY+=("DEFAULT")
		    fi
		    ;;

		list|ls)
		    if [ ${#COMP_WORDS[@]} -eq 3 ]
		    then
			COMPREPLY+=("FORCE")
		    fi
		    ;;
		
		upgrade)
		    if [ ${#COMP_WORDS[@]} -eq 3 ]
		    then
			COMPREPLY+=("RC")
		    fi
		    ;;
		
		configure|cf)
		    if [ ${#COMP_WORDS[@]} -eq 3 ]
		    then
			COMPREPLY=($(compgen -W "edit RESET" "${COMP_WORDS[2]}"))
		    fi
		    ;;
		
		install|installsign|is)
		    KRN_WORKSPACE=$(krn _GetVar KRN_WORKSPACE)
		    local _List=""
		    krn _UpdateCompletion

		    _List="$(grep -v -e ",ckc," -e ",cfg," $KRN_WORKSPACE/.CompletionList|cut -d',' -f1) \
                           $(grep       ",ckc,"            $KRN_WORKSPACE/.CompletionList|cut -d',' -f4)"
		    _List=$(echo $_List)
		    COMPREPLY=($(compgen -W "$_List" "${COMP_WORDS[${#COMP_WORDS[@]} - 1]}"))
		    ;;
		
		purge)
		    KRN_WORKSPACE=$(krn _GetVar KRN_WORKSPACE)
		    local _List=""
		    krn _UpdateCompletion

		    _List="$(grep -v -e ",ckc," $KRN_WORKSPACE/.CompletionList|cut -d',' -f1) \
                           $(grep       ",ckc," $KRN_WORKSPACE/.CompletionList|cut -d',' -f4)"
		    _List=$(echo $_List)
		    COMPREPLY=($(compgen -W "$_List" "${COMP_WORDS[${#COMP_WORDS[@]} - 1]}"))
		    ;;

		# krn Commande P1  P2
		# CW0 CW1      CW2 CW3
		confcomp*|kcc*)
		    if [ ${#COMP_WORDS[@]} -eq 4 ]
		    then
			_krn_completion_configfile ${COMP_WORDS[3]}
		    fi
		    ;;

		# krn Commande Version Label Config
		# CW0 CW1      CW2     CW3   CW4
		kernelconfig|kc)
		    if [ ${#COMP_WORDS[@]} -eq 5 ]
		    then
			_krn_completion_configfile ${COMP_WORDS[4]}
			[ "${COMP_WORDS[4]:0:1}" != "c" ] && COMPREPLY+=("default")
		    fi
		    ;;
		
		*)
	    esac
	    ;;
	*)
    esac
}
complete -F _krn_completion krn
