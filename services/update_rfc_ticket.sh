source "secrets.sh"

curl -X POST "https://servicenow-test.dhl.com/cchm_change_request_update" \
    -u username:password \
    -H "Content-Type: text/xml; charset=utf-8" \
    -H "SOAPAction: https://servicenow-test.dhl.com/cchm_change_request_update.do?SOAP" \
    --data-binary @../envelops/prod/update.xml
