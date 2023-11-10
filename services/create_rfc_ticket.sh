#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <USERNAME> <PASSWORD>"
    exit 1
fi

USERNAME=$1
PASSWORD=$2

curl -X POST "https://soap.servicenow-uat.dhl.com/cchm_change_request_create.do?SOAP" \
    --user "$USERNAME:$PASSWORD" \
    -H "Content-Type: text/xml; charset=utf-8" \
    --data-binary "@envelops/uat/create.xml" \
    > "/responses/uat/create_response.xml"
