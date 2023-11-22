#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <USERNAME> <PASSWORD>"
    exit 1
fi

USERNAME=$1
PASSWORD=$2
ENV=$3

case $3 in
    uat|UAT|Uat) URL="https://soap.servicenow-uat.dhl.com/cchm_change_request_update.do?SOAP" ;;
    prod|PROD|Prod) URL="https://soap.servicenow.dhl.com/cchm_change_request_update.do?SOAP" ;;
    *) echo -e "$Red Invalid env, we only support [uat|prod] $Color_Off"; exit 1 ;;
esac

curl -X POST "$URL" \
    --user "$USERNAME:$PASSWORD" \
    -H "Content-Type: text/xml; charset=utf-8" \
    --data-binary "/envelops/${ENV}/update.xml" \
    > "/responses/${ENV}/update_response.xml"