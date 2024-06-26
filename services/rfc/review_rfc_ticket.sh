#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <USERNAME> <PASSWORD> <ENVIRONMENT>"
    exit 1
fi

USERNAME=$1
PASSWORD=$2
ENV=$3

case $3 in
    uat|UAT|Uat) URL="https://soap.servicenow-uat.company-name.com/cchm_change_request_update.do?SOAP" ;;
    prod|PROD|Prod) URL="https://soap.servicenow.company-name.com/cchm_change_request_update.do?SOAP" ;;
    *) echo -e "$Red Invalid env, we only support [uat|prod] $Color_Off"; exit 1 ;;
esac

curl -X POST "$URL" \
    --user "$USERNAME:$PASSWORD" \
    -H "Content-Type: text/xml; charset=utf-8" \
    -H "SOAPAction: updateToReview" \
    --data-binary "@/envelops/${ENV}/rfc/update.xml" \
    > "/responses/${ENV}/rfc/update_response.xml"