#!/bin/bash

source "secrets.sh"

curl -X POST "https://soap.servicenow-uat.dhl.com/cchm_change_request_update.do?SOAP" \
    --user "$USERNAME:$PASSWORD" \
    -H "Content-Type: text/xml; charset=utf-8" \
    --data-binary "@envelops/uat/close.xml" \
    > "responses/uat/close_response.xml"