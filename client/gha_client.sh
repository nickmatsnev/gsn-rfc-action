#!/bin/bash

### Program to manipulate RFC ticketing within Linux ###

################# Styles #################
source "/styles/colors.sh"
################# End of styles #################

################# Globals #################
source "/globals/globals.sh"
################# End of globals #################

################# Functions #################
source "/functions/print_envelope_attributes.sh"
source "/functions/print_response_envelope_attributes.sh"
source "/functions/save_output.sh"
################# End of functions #################

################# Check if the arguments are set correctly #################
email_regex="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$"

datetime_regex="^([0-9]{4})-([0-9]{2})-([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})$"

if [ "$#" -ne 11 ]; then
    echo -e "${Yellow} Incorrect number of arguments. Usage: $0 [email] [assignment_group] [u_application_name] [u_escalated_by] [u_change_coordinator] [description] [start_datetime] [end_datetime] [username] [password] [environment] $Color_Off"
    echo -e "${Yellow} You have entered $# parameters $Color_Off"
    exit 1
fi

if [[ ! "$1" =~ $email_regex ]]; then
    echo -e "${Yellow} The first argument must be a valid email address. $Color_Off"
    exit 1
fi

if [[ ! "$4" =~ $email_regex ]]; then
    echo -e "${Yellow} The fourth argument must be a valid email address. $Color_Off"
    exit 1
fi

if [[ ! "$5" =~ $email_regex ]]; then
    echo -e "${Yellow} The fifth argument must be a valid email address. $Color_Off"
    exit 1
fi
if ! [[ "$7" =~ $datetime_regex ]] || ! [[ "$8" =~ $datetime_regex ]]; then
    echo -e "${Yellow} The third and fourth arguments must be in datetime format (YYYY-MM-DD HH:MM:SS). $Color_Off"
    exit 1
fi

start_date_sec=$(date -u -d "$7" +%s)
end_date_sec=$(date -u -d "$8" +%s)

case $11 in
    uat|UAT|Uat) environment="uat" ;;
    prod|PROD|Prod) environment="prod" ;;
    *) echo -e "$Red Invalid environment. Use UAT or PROD. Current environment is ${11} $Color_Off"; exit 1 ;;
esac
if [ "$start_date_sec" -ge "$end_date_sec" ]; then
    echo -e "${Yellow} The start date must be earlier than the end date. $Color_Off"
    exit 1
fi

echo -e "${Yellow} Starting RFC Ticket creation $Color_Off"
################# End of check if the arguments are set correctly #################


################# Printing the envelope attributes #################
print_envelope_attributes "create" "$environment"
################# End of printing the envelope attributes #################


################# Modifying ticket as it is set by user in GitHub Actions #################
xml_data=$(cat "/envelops/${environment}/create.xml")

xml_data=$(echo "$xml_data" | sed \
    -e "s|<short_description>[^<]*</short_description>|<short_description>$6</short_description>|g" \
    -e "s|<u_requested_by>[^<]*</u_requested_by>|<u_requested_by>$1</u_requested_by>|g" \
    -e "s|<assignment_group>[^<]*</assignment_group>|<assignment_group>$2</assignment_group>|g" \
    -e "s|<u_application_name>[^<]*</u_application_name>|<u_application_name>$3</u_application_name>|g" \
    -e "s|<u_escalated_by>[^<]*</u_escalated_by>|<u_escalated_by>$4</u_escalated_by>|g" \
    -e "s|<u_change_coordinator>[^<]*</u_change_coordinator>|<u_change_coordinator>$5</u_change_coordinator>|g" \
    -e "s|<start_date>[^<]*</start_date>|<start_date>$7</start_date>|g" \
    -e "s|<end_date>[^<]*</end_date>|<end_date>$8</end_date>|g" \
    )

echo "$xml_data"

echo "$xml_data" > "/envelops/${environment}/create.xml"
################# End of modifying ticket as it is set by user in GitHub Actions #################

################# Creating the RFC ticket #################
bash "/services/create_rfc_ticket.sh" "$9" "$10" "${environment}"

print_response_envelope_attributes "create" "${environment}"

TICKET_NUMBER=$(sed -n 's|.*<number>\(.*\)</number>.*|\1|p' /responses/${environment}/create_response.xml)

echo -e "$Green Ticket number: $TICKET_NUMBER $Color_Off\n"

if [ -z "$TICKET_NUMBER" ]; then
    echo "No ticket number found in the XML file."
    exit 1
fi
################# End of creating the RFC script #################

################# Updating to closure of the RFC ticket #################
xml_data=$(cat "/envelops/${environment}/close.xml")

xml_data=$(echo "$xml_data" | sed "s|<change_request>[^<]*</change_request>|<change_request>${TICKET_NUMBER}</change_request>|g")

echo "$xml_data"

echo "$xml_data" > "/envelops/${environment}/close.xml"

if [ $? -eq 0 ]; then
    echo "The number was successfully inserted into the XML file."
else
    echo "Failed to insert the number into the XML file."
fi

bash "/services/close_rfc_ticket.sh" "$9" "$10" "${environment}"

print_response_envelope_attributes "close" "${environment}"
################# End of updating to closure of the RFC script #################

################# Printing the output #################
echo -e "$Green Finishing the RFC ticket... $Color_Off"
################# End of printing the output #################
