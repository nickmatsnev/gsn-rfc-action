#!/bin/bash

### Program to manipulate RFC ticketing within Linux ###

################# Styles #################
source "styles/colors.sh"
################# End of styles #################

################# Globals #################
source "globals/globals.sh"
source "secrets.sh"
################# End of globals #################

################# Functions #################
source "functions/print_envelope_attributes.sh"
source "functions/print_response_envelope_attributes.sh"
source "functions/save_output.sh"
################# End of functions #################

################# Check if the arguments are set correctly #################
if [ "$#" -ne 2 ]; then
    if [ "$1" = "create" ] || [ "$1" = "cr" ]; then
        echo -e "${Yellow} Starting RFC Ticket creation $Color_Off"
    else
        echo -e "$Yellow How to use: $0 [create|cr|update|u|close|cl|read|r] RFCXXXXXXX [username] [password] $Color_Off"
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
print_envelope_attributes "$ACTION"
################# End of printing the envelope attributes #################

################# create with description #################
if [ "$1" = "create" ] || [ "$1" = "cr" ]; then
    if [ "$#" -eq 2 ]; then
        NEW_SHORT_DESCRIPTION=$2

        # Load the XML data from file
        xml_data=$(cat "envelops/uat/create.xml")

        # Store the old value of short description for possible future use or display
        old_value=$(echo "$xml_data" | grep -oP "(?<=<short_description>)[^<]+(?=</short_description>)")

        # Update the XML data with the new short description
        xml_data=$(echo "$xml_data" | sed "s|<short_description>[^<]*</short_description>|<short_description>${NEW_SHORT_DESCRIPTION}</short_description>|g")

        echo "Fast RFC creation"

        # Save the updated XML data back to file
        echo "$xml_data" > "envelops/uat/${ACTION}.xml"
        echo -e "$Blue Current value of description is:\n$old_value $Color_Off"
        echo -e "$Yellow New value of description is:\n${NEW_SHORT_DESCRIPTION} $Color_Off"
        is_create_with_description=true
        echo "$xml_data" > "envelops/uat/${ACTION}.xml"
    fi
fi
################# end of create with description #################

################# Editing the envelope attributes #################
if [ "$1" = "create" ] || [ "$1" = "cr" ] || [ "$1" = "update" ] || [ "$1" = "u" ]; then
    if [ "$is_create_with_description" = false ]; then
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
fi
################# End of editing the envelope attributes #################

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
# TODO fix the requests to work
# TODO continue to split client into functions
bash "services/${ACTION}_rfc_ticket.sh" "${TICKET_NUMBER}" "$3" "$4"
################# End of calling the service script #################

################# Printing the response #################
print_response_envelope_attributes "$ACTION"

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
    save_output "$ACTION"
else
    echo -e "$Blue The action is not create or update, so we do not alter anything. $Color_Off"
fi
################# End of saving the output #################