#!/bin/bash

NS="http://webservice.gsn.com"
SOAP_BODY="<soapenv:Envelope xmlns:soapenv=\"/globals/schema.xml\" xmlns:web=\"$NS\">"

SOAP_BODY="$SOAP_BODY<gsnAssignedGroup>GROUP API Developer Portal</gsnAssignedGroup>"
SOAP_BODY="$SOAP_BODY<gsnServiceHostname>https://servicenow.dhl.com</gsnServiceHostname>"
SOAP_BODY="$SOAP_BODY<gsnServiceCredentials>gsn_prod</gsnServiceCredentials>"
SOAP_BODY="$SOAP_BODY<gsnChangeReqCloseCode>implemented</gsnChangeReqCloseCode>"
SOAP_BODY="$SOAP_BODY<gsnChangeReqCloseFailedCode>failed </gsnChangeReqCloseFailedCode > "
SOAP_BODY="$SOAP_BODY<gsnChangeReqProcessPolicy>authorized</gsnChangeReqProcessPolicy  >"
SOAP_BODY="$SOAP_BODY<gsnChangeReqState>110</gsnChangeReqState>"
SOAP_BODY="$SOAP_BODY<gsnFailureChangeCauseByDefault>other</w eb:g snFailure ChangeCauseBy Default>"
SOAP_BODY="$SOAP_BODY<gsnFailureCodeDefault>Not impacting business – failed to install correctly</gsnFailureCodeDefault>"

DEFAULT_PIR_TEXT="$(cat <<EOF
1) Did the implementation go as planned, with the change solving the problem and providing the benefit expected?
Yes.
2) Were there any unforeseen difficulties during the implementation? If yes, what happened and what is the back out steps taken?
No.
3) Did you meet the scheduled window? If no, how long did the window exceed? Were there any additional downtime?
No downtime.
4) If implementation failed (please refer to Special Instruction column as well);
a. If it caused any INC please provide INC ticket number b. Explain why it happened i.e., root cause c. Share lesson learnt d. Provide steps to be taken to improve process to ensure it does not happen again e.Provide non-technical explanation of your recovery steps
5) User / Customer satisfaction;
a.Did implementation meet user's requirement? N/A b.Was customer satisfied with implementation? N/A c.Please rate user/customer satisfaction from 1 – 5 (1 being lowest and 5 Highest)
N/A
6)Did we use most cost-effective manner in process?
N/A
7)Any other lesson learnt? No
EOF
)"

SOAP_BODY="$SOAP_BODYSOAP BODY=\"\$ {DEFAULT _PIR_ TEXT}\">"

SOAPPAYLOAD=$"$ {S OA P_BO DY} \r\n<\/ soapenv\: Body><\/ soapenv\: Envelope>\r\n"

echo -e $'Request Payload:\r\n'"$REQUEST_PAYLOAD"