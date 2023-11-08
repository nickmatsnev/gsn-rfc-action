#!/bin/bash

### Program to manipulate RFC ticketing within Linux ###

################# Styles #################
source "styles/colors.sh"
################# End of styles #################

################# Globals #################
source "globals/globals.sh"
################# End of globals #################

################# Functions #################
source "functions/print_envelope_attributes.sh"
source "functions/print_response_envelope_attributes.sh"
source "functions/save_output.sh"
################# End of functions #################

################# Check if the arguments are set correctly #################
email_regex="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$"

datetime_regex="^([0-9]{4})-([0-9]{2})-([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})$"

if [ "$#" -ne 6 ]; then
    echo -e "${Yellow} Incorrect number of arguments. Usage: $0 [email] [description] [start_datetime] [end_datetime] [username] [password] $Color_Off"
    exit 1
fi

if [[ ! "$1" =~ $email_regex ]]; then
    echo -e "${Yellow} The first argument must be a valid email address. $Color_Off"
    exit 1
fi

if ! [[ "$3" =~ $datetime_regex ]] || ! [[ "$4" =~ $datetime_regex ]]; then
    echo -e "${Yellow} The third and fourth arguments must be in datetime format (YYYY-MM-DD HH:MM:SS). $Color_Off"
    exit 1
fi

start_date_sec=$(date -u -d "$3" +%s)
end_date_sec=$(date -u -d "$4" +%s)

if [ "$start_date_sec" -ge "$end_date_sec" ]; then
    echo -e "${Yellow} The start date must be earlier than the end date. $Color_Off"
    exit 1
fi

echo -e "${Yellow} Starting RFC Ticket creation $Color_Off"
################# End of check if the arguments are set correctly #################


################# Printing the envelope attributes #################
print_envelope_attributes "create"
################# End of printing the envelope attributes #################


################# Modifying ticket as it is set by user in GitHub Actions #################
NEW_SHORT_DESCRIPTION=$1

xml_data=$(cat "envelops/uat/create.xml")

xml_data=$(echo "$xml_data" | sed "s|<web:short_description>[^<]*</web:short_description>|<web:short_description>${NEW_SHORT_DESCRIPTION}</web:short_description>|g")

echo "$xml_data"

echo "$xml_data" > "envelops/uat/create.xml"
################# End of modifying ticket as it is set by user in GitHub Actions #################

################# Creating the RFC ticket #################
bash "services/create_rfc_ticket.sh" "$5" "$6"

print_response_envelope_attributes "create"

TICKET_NUMBER=$(sed -n 's|.*<number>\(.*\)</number>.*|\1|p' responses/uat/create_response.xml)

echo -e "$Green Ticket number: $TICKET_NUMBER $Color_Off\n"

if [ -z "$TICKET_NUMBER" ]; then
    echo "No ticket number found in the XML file."
    exit 1
fi
################# End of creating the RFC script #################

################# Updating to closure of the RFC ticket #################
xml_data=$(cat "envelops/uat/close.xml")

xml_data=$(echo "$xml_data" | sed "s|<change_request>[^<]*</change_request>|<change_request>${TICKET_NUMBER}</change_request>|g")

echo "$xml_data"

echo "$xml_data" > "envelops/uat/close.xml"

if [ $? -eq 0 ]; then
    echo "The number was successfully inserted into the XML file."
else
    echo "Failed to insert the number into the XML file."
fi

bash "services/close_rfc_ticket.sh" "$5" "$6"

print_response_envelope_attributes "close"
################# End of updating to closure of the RFC script #################

################# Printing the output #################
echo -e "$Green Finishing the RFC ticket... $Color_Off"
################# End of printing the output #################