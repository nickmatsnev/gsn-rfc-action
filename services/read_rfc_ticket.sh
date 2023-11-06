#!/bin/bash

source "secrets.sh"

curl -X POST "https://soap.servicenow-uat.dhl.com/cchm_change_request_read.do?SOAP" \
    --user "$USERNAME:$PASSWORD" \
    -H "Content-Type: text/xml; charset=utf-8" \
    --data-binary "@envelops/uat/read.xml" \
    > "responses/uat/read_response.xml"