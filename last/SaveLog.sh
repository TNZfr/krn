#!/bin/bash

#------------------------------------------------------------------------------------------------
# main
#

if [ "$KRN_ACCOUNTING" = "" ]
then
    echo ""
    echo "*** Accounting disabled, no files to be saved. ***"
    echo ""
    exit 0
fi

KRN_LOGTGZ=KRNLOG-$(uname -n)-${LOGNAME}-$(date +%Y%m%d-%Hm%Mm%Ss).tgz

cd $KRN_ACCOUNTING
tar cfz $KRN_LOGTGZ *.log
[ $? -eq 0 ] && rm -f *.log

echo ""
printf "Archive file \033[33;44m $KRN_ACCOUNTING/$KRN_LOGTGZ \033[m created.\n"
echo ""

exit 0
