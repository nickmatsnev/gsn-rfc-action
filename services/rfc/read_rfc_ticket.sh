#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <USERNAME> <PASSWORD> <ENVIRONMENT>"
    exit 1
fi

USERNAME=$1
PASSWORD=$2
ENV=$3

case $ENV in
    uat|UAT|Uat) URL="https://soap.servicenow-uat.dhl.com/change_task.do?SOAP" ;;
    prod|PROD|Prod) URL="https://soap.servicenow.dhl.com/change_task.do?SOAP" ;;
    *) echo "Invalid env, we only support [uat|prod]"; exit 1 ;;
esac

# case $ENV in
#     uat|UAT|Uat) WSDL_URL="https://soap.servicenow-uat.dhl.com/change_task.do?WSDL" ;;
#     prod|PROD|Prod) WSDL_URL="https://soap.servicenow.dhl.com/change_task.do?WSDL" ;;
#     *) echo "Invalid env, we only support [uat|prod]"; exit 1 ;;
# esac

# curl -X GET "$WSDL_URL" \
#     --user "$USERNAME:$PASSWORD" \
#     -o "wsdl_${ENV}.xml"

curl -X POST ${URL} \
    --user "$USERNAME:$PASSWORD" \
    -H "Content-Type: text/xml; charset=utf-8" \
    --data-binary @/envelops/${ENV}/rfc/read.xml \
    > "/responses/${ENV}/rfc/read_response.xml"
# good response:
# <?xml version='1.0' encoding='UTF-8'?>
# <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
# <SOAP-ENV:Body><getKeysResponse xmlns="https://servicenow.dhl.com/ns/change_task/">
# <sys_id>2cdc352197ab71d082c01e800153aff8,50dc352197ab71d082c01e800153aff1,60dc752197ab71d082c01e800153af56</sys_id>
# <count>3</count>
# </getKeysResponse>
# </SOAP-ENV:Body>
# </SOAP-ENV:Envelope>
