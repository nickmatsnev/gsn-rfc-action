#!/bin/bash

USERNAME=""
PASSWORD=""

curl -u $USERNAME:$PASSWORD https://soap.servicenow-uat.dhl.com/cchm_change_request_create.do?WSDL -o wsdl.xml
