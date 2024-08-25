#!/bin/bash

. $KRN_EXE/lib/kernel.sh

#-------------------------------------------------------------------------------
# Main
#

if [ $# -lt 2 ]
then
    echo ""
    echo "Syntax : ${KRN_Help_Prefix}CreateSignature Filename SignerName"
    echo "  Filename   : Basename for certifcate files (without extension)"
    echo "  SignerName : Signer Name for certificates"
    echo ""
    exit 1
fi

Filename=$1
SignerName="$2"

Debut=$(TopHorloge)
cd $HOME/.krn
echo ""
printh "Creating PRIV and DER certicate files for : $SignerName"
openssl req -new -x509 -newkey rsa:2048 -keyout ${Filename}.priv -outform DER -out ${Filename}.der -days 36500 -subj "/CN=${SignerName}/"
if [ $? -ne 0 ]
then
    rm -f ${Filename}.priv
    echo ""
    echo "ERROR : Check in previous log message"
    echo ""
    exit 1
fi

printh "${Filename}.der copy/convertion to ${Filename}.pem"
openssl x509 -inform der -in ${Filename}.der -out ${Filename}.pem

# Remove PRIV key password
# ------------------------
echo ""
printf "Do you want to remove private key password (y/N) : "; read Reponse
echo ""
Reponse=$(echo $Reponse|tr [:upper:] [:lower:])
if [ "$Reponse" = "y" ]
then
    openssl rsa -in ${Filename}.priv  -out ${Filename}.priv-nopwd
    mv -f           ${Filename}.priv-nopwd ${Filename}.priv
fi

# Enroll key in UEFI dbx
# ----------------------
echo ""
printf "Do you want to enroll ${Filename}.der in UEFI/Secure Boot(y/N) : "; read Reponse
echo ""
Reponse=$(echo $Reponse|tr [:upper:] [:lower:])
if [ "$Reponse" = "y" ]
then
    printh "Enrolling ${Filename}.der/signer ${SignerName}"
    $KRN_sudo mokutil --import ${Filename}.der
    echo ""
    printf "\033[30;46m %-60s \033[m\n" " "
    printf "\033[30;46m %-60s \033[m\n" "You must reboot your computer fo finalyze enrollment"
    printf "\033[30;46m %-60s \033[m\n" "The password you just gave is going to be required. "
    printf "\033[30;46m %-60s \033[m\n" ""
    printf "\033[30;46m %-60s \033[m\n" "Don't forget you'll have a QWERTY keyboard mapping"
    printf "\033[30;46m %-60s \033[m\n" " "
else
    printf "\033[30;46m %-60s \033[m\n" " "
    printf "\033[30;46m %-60s \033[m\n" "You answered NO. To enroll later, the command is :"
    printf "\033[30;46m %-60s \033[m\n" "$KRN_sudo mokutil --import $PWD/${Filename}.der"
    printf "\033[30;46m %-60s \033[m\n" " "
fi

echo ""
echo "Certficate files created in $PWD :"
ls -l ${Filename}.*
echo ""

printf "\033[30;46m %-60s \033[m\n" " "
printf "\033[30;46m %-60s \033[m\n" "To use the new certificates in KRN,"
printf "\033[30;46m %-60s \033[m\n" "you must run the following command :"
printf "\033[30;46m %-60s \033[m\n" " krn Configure RESET"
printf "\033[30;46m %-60s \033[m\n" " "

echo   ""
printf "\033[44m CreateSignature elapsed \033[m : $(AfficheDuree $Debut $(TopHorloge))\n"
echo   ""

exit 0

