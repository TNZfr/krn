
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
    if [ ${#COMP_WORDS[@]} -gt 1 ]
    then
	case $(echo ${COMP_WORDS[1]}|tr [:upper:] [:lower:]) in
	    watch|wa|detach|dt|curses|cu)
		local _Last=${COMP_WORDS[${#COMP_WORDS[@]}-1]}
		
		#echo -en "\n${#COMP_WORDS[@]} : [${COMP_WORDS[1]}] : ${COMP_WORDS[*]} -> "
		
		unset COMP_WORDS[1]
		COMP_WORDS=(${COMP_WORDS[*]})
		[ -z "$_Last" ] && COMP_WORDS+=("")
		
		#echo "${#COMP_WORDS[@]} : [${COMP_WORDS[1]}] : ${COMP_WORDS[*]}"
		;;
	esac
    fi
    
    case ${#COMP_WORDS[@]} in
	1|2)
	    KRN_EXE=$(krn _GetVar KRN_EXE)
	    COMPREPLY=($(grep -i "^${COMP_WORDS[1]}" $KRN_EXE/_Completion.dat|cut -d',' -f2|sort|uniq))
	    ;;
	3)
	    case $(echo ${COMP_WORDS[1]}|tr [:upper:] [:lower:]) in
		# Param2 = Installed Kernels
		remove|verifykernel|vk|sign|sk)
		    _kernel_versions;
		    ;;
		
		# Param2 = Config file in workspace
		setconfig|sc)
		    _krn_completion_configfile ${COMP_WORDS[2]};
		    COMPREPLY+=("DEFAULT")
		    ;;

		configure|cf)
		    COMPREPLY+=("RESET")
		    ;;
		
		install|installsign|is)
		    KRN_WORKSPACE=$(krn _GetVar KRN_WORKSPACE)
		    local _List=""
		    krn _UpdateCompletion

		    _List="$(grep -v -e ",ckc," -e ",cfg," $KRN_WORKSPACE/.CompletionList|cut -d',' -f1) \
                           $(grep       ",ckc,"            $KRN_WORKSPACE/.CompletionList|cut -d',' -f4)"
		    _List=$(echo $_List)
		    COMPREPLY=($(compgen -W "$_List" "${COMP_WORDS[2]}"))
		    ;;
		
		purge)
		    KRN_WORKSPACE=$(krn _GetVar KRN_WORKSPACE)
		    local _List=""
		    krn _UpdateCompletion

		    _List="$(grep -v -e ",ckc," $KRN_WORKSPACE/.CompletionList|cut -d',' -f1) \
                           $(grep       ",ckc," $KRN_WORKSPACE/.CompletionList|cut -d',' -f4)"
		    _List=$(echo $_List)
		    COMPREPLY=($(compgen -W "$_List" "${COMP_WORDS[2]}"))
		    ;;
		
		*)
	    esac
	    ;;

	4)
	    # krn Commande P1  P2
	    # CW0 CW1      CW2 CW3
	    case $(echo ${COMP_WORDS[1]}|tr [:upper:] [:lower:]) in
		confcomp*|kcc*)
		    _krn_completion_configfile ${COMP_WORDS[3]};		
		    ;;
	    esac
	    ;;
	
	5)
	    # krn Commande P1  P2  P3
	    # CW0 CW1      CW2 CW3 CW4
	    case $(echo ${COMP_WORDS[1]}|tr [:upper:] [:lower:]) in
		kernelconfig|kc)
		    _krn_completion_configfile ${COMP_WORDS[4]};
		    COMPREPLY+=("default")
		    ;;
	    esac
	    ;;

	*)
    esac
}

complete -F _krn_completion krn


