curl -X -v POST "https://servicenow-test.dhl.com" \
    -H "Content-Type: text/xml; charset=utf-8" \
    -H "SOAPAction: https://servicenow-test.dhl.com/cchm_change_request_read.do?SOAP" \
    --data-binary @envelops/prod/read.xml > output_get.xml
