#!/bin/bash

### Program to manipulate RFC ticketing within Linux ###


################# Styles #################
source "styles/colors.sh"
################# End of styles #################


################# Globals #################
source "globals/globals.sh"
################# End of globals #################


################# Functions #################
source "functions/client/print_envelope_attributes.sh"
source "functions/client/print_response_envelope_attributes.sh"
source "functions/client/save_output.sh"
################# End of functions #################


################# Check if the arguments are set correctly #################
if [ "$#" -ne 5 ]; then
    if [ "$1" = "create" ] || [ "$1" = "cr" ]; then
        echo -e "${Yellow} Starting RFC Ticket creation $Color_Off"
    else
        echo -e "$Yellow How to use: $0 [create|cr|update|u|close|cl|read|r] RFCXXXXXXX [username] [password] [environment] $Color_Off"
        exit 1
    fi
fi
################# End of check if the arguments are set correctly #################


################# Checking if the arguments values are correct #################
case $1 in
    create|cr) action="create" ;;
    update|u) action="update" ;;
    close|cl) action="close" ;;
    read|r) action="read" ;;
    *) echo -e "$Red Invalid action. Use create|cr, update|u, read|r or close|cl $Color_Off"; exit 1 ;;
esac

# check if create with description
if [ "$1" = "create" ] || [ "$1" = "cr" ]; then
    if [ "$#" -eq 5 ]; then
      description=$2
      username=$3
      password=$4
      env=$5
    else
      username=$2
      password=$3
      env=$4
    fi
else
    username=$3
    password=$4
    env=$5
fi
################# End of checking if the arguments values are correct #################


################# Printing the envelope attributes #################
print_envelope_attributes "$action" "$env"
################# End of printing the envelope attributes #################


################# create with description #################
if [ "$1" = "create" ] || [ "$1" = "cr" ]; then
    if [ "$#" -eq 5 ]; then

        # Load the XML data from file
        xml_data=$(cat "envelops/${env}/rfc/create.xml")

        # Store the old value of short description for possible future use or display
        old_value=$(echo "$xml_data" | grep -oP "(?<=<short_description>)[^<]+(?=</short_description>)")

        # Update the XML data with the new short description
        xml_data=$(echo "$xml_data" | sed "s|<short_description>[^<]*</short_description>|<short_description>${description}</short_description>|g")

        echo "Fast RFC creation"

        # Save the updated XML data back to file
        echo "$xml_data" > "envelops/${env}/rfc/${action}.xml"
        echo -e "$Blue Current value of description is:\n$old_value $Color_Off"
        echo -e "$Yellow New value of description is:\n${description} $Color_Off"
        echo "$xml_data" > "envelops/${env}/rfc/${action}.xml"
    fi
fi
################# end of create with description #################


################# Editing the envelope attributes #################
if [ "$1" = "create" ] || [ "$1" = "cr" ] || [ "$1" = "update" ] || [ "$1" = "u" ]; then
    input_xml="envelops/${env}/rfc/${action}.xml"
    xml_data=$(cat "$input_xml")

    tags=($(grep -oP '<\K[^>]+(?=>[^<]+<\/[^>]+>)' "$input_xml"))

    for tag in "${tags[@]}"; do
        old_value=$(grep -oP "(?<=<$tag>)[^<]+" "$input_xml")

        echo -e "$Blue Current value of $tag is $old_value $Color_Off"
        read -p "$Yellow Enter new value (or press enter to keep the old value):" new_value
        echo -e "$Color_Off"

        # if new value is present, we update
        if [[ -n "$new_value" ]]; then
            xml_data=$(echo -e "$xml_data" | sed "s|<$tag>$old_value</$tag>|<$tag>$new_value</$tag>|")
        fi
    done

    echo "$xml_data"
    # here we change the envelope
    echo "$xml_data" > "$input_xml"
fi
################# End of editing the envelope attributes #################


################# Checking if the ticket number is valid #################
if [[ $2 =~ ^RFC[0-9]{7}$ ]]; then
    ticket_number=$2
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
bash "services/client/${action}_rfc_ticket.sh" "${username}" "${password}" "${env}"
################# End of calling the service script #################


################# Printing the response #################
print_response_envelope_attributes "$action" "${env}"

case $1 in
    create|cr) echo -e "$Green Finishing creating the ticket... $Color_Off" ;;
    update|u) echo -e "$Green Finishing updating the ticket... $Color_Off" ;;
    close|cl) echo -e "$Green Finishing closing the ticket... $Color_Off" ;;
    read|r) echo -e "$Green Finishing reading the ticket... $Color_Off" ;;
    *) echo -e "$Red Invalid action. Use create|cr, update|u, read|r or close|cl $Color_Off"; exit 1 ;;
esac
################# End of printing the response #################


################# Saving the output #################
if [ "$1" = "create" ] || [ "$1" = "cr" ] || [ "$1" = "update" ] || [ "$1" = "u" ]; then
    save_output "$action" "${env}"
else
    echo -e "$Blue The action is not create or update, so we do not alter anything. $Color_Off"
fi
################# End of saving the output #################
