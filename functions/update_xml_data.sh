#!/bin/bash

source "/functions/print_response_envelope_attributes.sh"

update_xml_data() {
    local environment=$1
    local ticket_number=$2
    local state_value=$3
    local username=$4
    local password=$5

    local xml_data=$(cat "/envelops/${environment}/update.xml")

    xml_data=$(echo "$xml_data" | sed "s|<change_request>[^<]*</change_request>|<change_request>${ticket_number}</change_request>|g")
    xml_data=$(echo "$xml_data" | sed -e "s|<state>[^<]*</state>|<state>${state_value}</state>|g")

    echo "$xml_data" > "/envelops/${environment}/update.xml"

    if [ $? -eq 0 ]; then
        echo "The number was successfully inserted into the XML file."
    else
        echo "Failed to insert the number into the XML file."
    fi

    bash "/services/rfc/update_rfc_ticket.sh" "$username" "$password" "${environment}"

    print_response_envelope_attributes "update" "${environment}"
}