#!/bin/bash

function save_output() {
    local ACTION=$1
    echo -e "$Green Saving the output... $Color_Off"

    xml_response_data="responses/${ACTION}_response.xml"

    rfc_ticket=$(grep -oP '<number>\K[^<]+' "$xml_response_data")

    if [ -z "$rfc_ticket" ]; then
        echo "Value could not be extracted. Check your XML file and path."
        exit 1
    fi
    echo "$rfc_ticket" > responses/ticket_numbers/"$rfc_ticket".txt
    echo "Value is saved to $rfc_ticket.txt"
}