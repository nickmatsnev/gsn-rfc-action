#!/bin/bash

### Program to manipulate RFC ticketing within Linux ###

################# Styles #################

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Reset
Color_Off='\033[0m'       # Text Reset

################# End of styles #################

################# Check if the arguments are set correctly #################
if [ "$#" -ne 2 ]; then
    if [ "$1" = "create" ] || [ "$1" = "cr" ]; then
        echo -e "${Yellow} Starting RFC Ticket creation $Color_Off"
    else
        echo -e "$Yellow How to use: $0 [create|cr|update|u|close|cl|read|r] RFCXXXXXXX $Color_Off"
        exit 1
    fi
fi
################# End of check if the arguments are set correctly #################


################# Checking if the arguments values are correct #################
case $1 in
    create|cr) ACTION="create" ;;
    update|u) ACTION="update" ;;
    close|cl) ACTION="close" ;;
    read|r) ACTION="read" ;;
    *) echo -e "$Red Invalid action. Use create|cr, update|u, read|r or close|cl $Color_Off"; exit 1 ;;
esac
################# End of checking if the arguments values are correct #################

################# Printing the envelope attributes #################
echo -e "$Blue Envelope attributes: $Color_Off"
cat "envelops/test/${ACTION}.xml" | grep -E "<[a-z]+>"
input_xml="envelops/test/${ACTION}.xml"
if [[ ! -f "$input_xml" ]]; then
    echo -e "$Red Envelope $input_xml does not exist! $Color_Off"
    exit 1
fi


grep -oP '<web:\K[^>]+(?=>[^<]+<\/web:[^>]+>)' "$input_xml" | while read -r tag; do
    value=$(grep -oP "(?<=<web:$tag>)[^<]+" "$input_xml")
    echo -e "$Blue $tag:$value $Color_Off"
done

echo -e "$Blue Envelope attributes end $Color_Off"
################# End of printing the envelope attributes #################

NEW_SHORT_DESCRIPTION=$1

xml_data=$(cat "envelops/test/create_gha.xml")

xml_data=$(echo "$xml_data" | sed "s|<web:short_description>[^<]*</web:short_description>|<web:short_description>${NEW_SHORT_DESCRIPTION}</web:short_description>|g")

echo "$xml_data"

echo "$xml_data" > "envelops/test/${ACTION}.xml"

################# Checking if the ticket number is valid #################
if [[ $2 =~ ^RFC[0-9]{7}$ ]]; then
    TICKET_NUMBER=$2
else
    if [ "$1" = "create" ] || [ "$1" = "cr" ]; then
        echo -e "$Green Finishing creating the ticket... $Color_Off"
    else
        echo -e "$Red Invalid ticket number format. Use RFCXXXXXXX where X is a digit. $Color_Off"
        exit 1
    fi
fi
################# End of checking if the ticket number is valid #################

################# Calling the service script #################
bash "services/${ACTION}_rfc_ticket.sh" "${TICKET_NUMBER}"
################# End of calling the service script #################

################# Printing the output #################
echo -e "$Green Response: $Color_Off"
cat "output.xml"


case $1 in
    create|cr) echo -e "$Green Finishing creating the ticket... $Color_Off" ;;
    update|u) echo -e "$Green Finishing updating the ticket... $Color_Off" ;;
    close|cl) echo -e "$Green Finishing closing the ticket... $Color_Off" ;;
    read|r) echo -e "$Green Finishing reading the ticket... $Color_Off" ;;
    *) echo -e "$Red Invalid action. Use create|cr, update|u, read|r or close|cl $Color_Off"; exit 1 ;;
esac
################# End of printing the output #################