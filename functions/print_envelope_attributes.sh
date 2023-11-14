#!/bin/bash

function print_envelope_attributes() {
    local ACTION=$1
    echo -e "$Blue Envelope attributes: $Color_Off"
    cat "/envelops/uat/${ACTION}.xml" | grep -E "<[a-z]+>"
    input_xml="/envelops/uat/${ACTION}.xml"
    if [[ ! -f "$input_xml" ]]; then
        echo -e "$Red Envelope $input_xml does not exist! $Color_Off"
        exit 1
    fi

    grep -oP '<\K[^>]+(?=>[^<]+<\/[^>]+>)' "$input_xml" | while read -r tag; do
        value=$(grep -oP "(?<=<$tag>)[^<]+" "$input_xml")
        echo -e "$Blue $tag:$value $Color_Off"
    done

    echo -e "$Blue Envelope attributes end $Color_Off"
}