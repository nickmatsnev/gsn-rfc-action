#!/bin/bash

test_service() {
    local username=$1
    local password=$2
    local input_file=$3
    local expected_status=$4

    output=$(../../services/rfc/create_rfc_ticket.sh "$username" "$password" < "$input_file")
    response_status=$(echo "$output" | grep -oP '(?<=<response_status>).*?(?=</response_status>)')

    if [ "$response_status" == "$expected_status" ]; then
        echo "Test Passed: Expected '$expected_status', got '$response_status'"
    else
        echo "Test Failed: Expected '$expected_status', got '$response_status'"
    fi
}

# test_service "correct_username" "correct_password" "correct_input.xml" "OK"

# test_service "wrong_username" "wrong_password" "correct_input.xml" "FAILURE"
