source "secrets.sh"

curl -X -v "https://servicenow-test.dhl.com" \
    -u username:password \
    -H "Content-Type: text/xml; charset=utf-8" \
    -H "SOAPAction: https://servicenow-test.dhl.com/cchm_change_request_create.do?SOAP" \
    --data-binary @envelops/prod/create.xml > responses/create_response.xml
