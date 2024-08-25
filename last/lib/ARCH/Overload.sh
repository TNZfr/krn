
#-------------------------------------------------------------------------------
_OverloadModule ()
{
    _Version=$1

    VersionMin=60110001 # linux-version-num 6.11-rc1
    VersionCur=$(linux-version-num $_Version)

    if [ $VersionCur -ge $VersionMin ]
    then
	printh "Version $_Version -> \033[32mArch packages build\033[m"
	. $KRN_LIB/Overload-Module.sh
    else
	printh "Version $_Version -> \033[34mbzImage build\033[m"
	. $KRN_LIB/Module.sh
    fi
}
