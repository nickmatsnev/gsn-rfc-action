#!/bin/bash

function print_response_envelope_attributes() {
    local ACTION=$1

    echo -e "\n\n $Blue Response body: $Color_Off"
    cat "/responses/uat/${ACTION}_response.xml" | grep -E "<[a-z]+>"
    input_xml="/responses/uat/${ACTION}_response.xml"
    if [[ ! -f "$input_xml" ]]; then
        echo -e "$Red Envelope $input_xml does not exist! $Color_Off"
        exit 1
    fi
    echo -e "$Blue Response body end \n\n $Color_Off"

    echo -e "$Blue Response envelope attributes: $Color_Off"
    grep -oP '<\K[^>]+(?=>[^<]+<\/[^>]+>)' "$input_xml" | while read -r tag; do
        value=$(grep -oP "(?<=<$tag>)[^<]+" "$input_xml")
        echo -e "$Blue $tag:$value $Color_Off"
    done
    echo -e "$Blue Envelope attributes end $Color_Off"
}