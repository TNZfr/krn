#!/bin/bash

#-------------------------------------------------------------------------------
# Main
#
# Script run by KRN Detach to provide refresh option
#

$*

echo   ""
printf "Press a key to close ..."
read -n1 dummy
exit 0
