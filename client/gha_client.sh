#!/bin/bash

### Program to manipulate RFC ticketing within Linux ###

################# Styles #################
source "/styles/colors.sh"
################# End of styles #################

################# Globals #################
source "/globals/globals.sh"
################# End of globals #################

################# Functions #################
source "/functions/print_envelope_attributes.sh"
source "/functions/print_response_envelope_attributes.sh"
source "/functions/save_output.sh"
source "/functions/update_xml_data.sh"
################# End of functions #################

################# Check if the arguments are set correctly #################
email_regex="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$"

datetime_regex="^([0-9]{4})-([0-9]{2})-([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})$"

if [ "$#" -ne 36 ]; then
    echo -e "${Yellow} Incorrect number of arguments. Usage: $0 [email] [assignment_group] [u_application_name] [u_escalated_by] [u_change_coordinator] [description] [start_datetime] [end_datetime] [uat_ctask_description] [impl_ctask_description] [approval_type] [wait_for] [reject_handling] [sla_category] [approver] [maintenance_window] [impacted_service] [impacted_business_unit] [change_tested] [implementation_risk] [skip_risk] [known_impact] [backout_planned] [backout_authority] [backout_groups] [trigger_for_backout] [duration_of_backout] [backout_plan] [security_classification] [security_regulation] [build_run_activity] [country_notified] [cmdb_ci] [username] [password] [environment] $Color_Off"

    echo -e "${Yellow} You have entered $# parameters $Color_Off"
    exit 1
fi

if [[ ! "$1" =~ $email_regex ]]; then
    echo -e "${Yellow} The first argument must be a valid email address. $Color_Off"
    exit 1
fi

if [[ ! "$4" =~ $email_regex ]]; then
    echo -e "${Yellow} The fourth argument must be a valid email address. $Color_Off"
    exit 1
fi

if [[ ! "$5" =~ $email_regex ]]; then
    echo -e "${Yellow} The fifth argument must be a valid email address. $Color_Off"
    exit 1
fi
if ! [[ "$7" =~ $datetime_regex ]] || ! [[ "$8" =~ $datetime_regex ]]; then
    echo -e "${Yellow} The third and fourth arguments must be in datetime format (YYYY-MM-DD HH:MM:SS). $Color_Off"
    exit 1
fi

start_date_sec=${7}
end_date_sec=${8}
rtp_date=${start_date_sec%% *}
uat_ctask_description=${9}
impl_ctask_description=${10}
approval_type=${11}
wait_for=${12}
reject_handling=${13}
sla_category=${14}
approver=${15}
maintenance_window=${16}
impacted_service=${17}
impacted_business_unit=${18}
change_tested=${19}
implementation_risk=${20}
skip_risk=${21}
known_impact=${22}
backout_planned=${23}
backout_authority=${24}
backout_groups=${25}
trigger_for_backout=${26}
duration_of_backout=${27}
backout_plan=${28}
security_classification=${29}
security_regulation=${30}
build_run_activity=${31}
country_notified=${32}
cmdb_ci=${33}
username=${34}
password=${35}

case "${36}" in
    uat|UAT|Uat) environment="uat" ;;
    prod|PROD|Prod) environment="prod" ;;
    *) echo -e "${Red} Invalid environment. Use UAT or PROD. Current environment is ${13} $Color_Off"; exit 1 ;;
esac
start_date_sec_utc=$(date -d "$start_date_sec" +%s)
end_date_sec_utc=$(date -d "$end_date_sec" +%s)
if [ "$start_date_sec_utc" -ge "$end_date_sec_utc" ]; then
    echo -e "${Yellow} The start date must be earlier than the end date. $Color_Off"
    exit 1
fi

echo -e "${Yellow} Starting RFC Ticket creation $Color_Off"
################# End of check if the arguments are set correctly #################

################# Modifying ticket for creation as it is set by user in GitHub Actions #################
xml_data=$(cat "/envelops/${environment}/rfc/create.xml")

xml_data=$(echo "$xml_data" | sed \
    -e "s|<short_description>[^<]*</short_description>|<short_description>Deploy using FastFRC ${rtp_date}</short_description>|g" \
    -e "s|<description>[^<]*</description>|<description>$6</description>|g" \
    -e "s|<u_requested_by>[^<]*</u_requested_by>|<u_requested_by>$1</u_requested_by>|g" \
    -e "s|<assignment_group>[^<]*</assignment_group>|<assignment_group>$2</assignment_group>|g" \
    -e "s|<u_application_name>[^<]*</u_application_name>|<u_application_name>$3</u_application_name>|g" \
    -e "s|<u_escalated_by>[^<]*</u_escalated_by>|<u_escalated_by>$4</u_escalated_by>|g" \
    -e "s|<u_change_coordinator>[^<]*</u_change_coordinator>|<u_change_coordinator>$5</u_change_coordinator>|g" \
    -e "s|<start_date>[^<]*</start_date>|<start_date>${start_date_sec}</start_date>|g" \
    -e "s|<end_date>[^<]*</end_date>|<end_date>${end_date_sec}</end_date>|g" \
    -e "s|<u_customer_rtp_date>[^<]*</u_customer_rtp_date>|<u_customer_rtp_date>${rtp_date}</u_customer_rtp_date>|g" \
    )

echo "$xml_data"

echo "$xml_data" > "/envelops/${environment}/rfc/create.xml"
################# End of modifying ticket for creation as it is set by user in GitHub Actions #################

################# Creating the RFC ticket #################
bash "/services/rfc/create_rfc_ticket.sh" "${username}" "${password}" "${environment}"

print_response_envelope_attributes "rfc" "create" "${environment}"

TICKET_NUMBER=$(sed -n 's|.*<number>\(.*\)</number>.*|\1|p' /responses/${environment}/rfc/create_response.xml)
SYS_ID_RFC=$(sed -n 's|.*<sys_id>\(.*\)</sys_id>.*|\1|p' /responses/${environment}/rfc/create_response.xml)

echo -e "$Green Ticket number: $TICKET_NUMBER $Color_Off\n"

if [ -z "$TICKET_NUMBER" ]; then
    echo "No ticket number found in the XML file."
    exit 1
fi
################# End of creating the RFC script #################

################# Read CTasks and other stuff ###############
# xml_data=$(cat "/envelops/${environment}/rfc/read.xml")
# xml_data=$(echo "$xml_data" | sed -e "s|<change_request>[^<]*</change_request>|<change_request>${TICKET_NUMBER}</change_request>|g")
# echo "$xml_data" > "/envelops/${environment}/rfc/read.xml"

bash "/services/rfc/read_rfc_ticket.sh" "${username}" "${password}" "${environment}"

print_response_envelope_attributes "rfc" "read" "${environment}"

echo -e "start of envelope\n\n\n\n"
echo $(cat /responses/${environment}/rfc/read_response.xml)

echo -e "\n\n\n\n end of envelope\n\n\n\n"
################# End of read CTasks and other stuff ###############

################# Create group approval #################
xml_data=$(cat "/envelops/${environment}/groupapprove/create.xml")

xml_data=$(echo "$xml_data" | sed -e "s|<change_request>[^<]*</change_request>|<change_request>${TICKET_NUMBER}</change_request>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_approval_type>[^<]*</u_approval_type>|<u_approval_type>${approval_type}</u_approval_type>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<assignment_group>[^<]*</assignment_group>|<assignment_group>CAB-BIMODAL</assignment_group>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<wait_for>[^<]*</wait_for>|<wait_for>${wait_for}</wait_for>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<reject_handling>[^<]*</reject_handling>|<reject_handling>${reject_handling}</reject_handling>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_sla_category>[^<]*</u_sla_category>|<u_sla_category>${sla_category}</u_sla_category>|g")

echo "$xml_data" > "/envelops/${environment}/groupapprove/create.xml"

bash "/services/groupapprove/create_group_approval.sh" "${username}" "${password}" "${environment}"
print_response_envelope_attributes "groupapprove" "create" "${environment}"

GAPPR_NUMBER=$(sed -n 's|.*<number>\(.*\)</number>.*|\1|p' /responses/${environment}/groupapprove/create_response.xml)
################# End of creation of group approval #################


################# Create approver #################
xml_data=$(cat "/envelops/${environment}/approver/create.xml")

xml_data=$(echo "$xml_data" | sed -e "s|<sysapproval_group>[^<]*</sysapproval_group>|<sysapproval_group>${GAPPR_NUMBER}</sysapproval_group>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<change_request>[^<]*</change_request>|<change_request>${TICKET_NUMBER}</change_request>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<approver>[^<]*</approver>|<approver>${approver}</approver>|g")

echo "$xml_data" > "/envelops/${environment}/approver/create.xml"

bash "/services/approver/create_approver.sh" "${username}" "${password}" "${environment}"

print_response_envelope_attributes "approver" "create" "${environment}"
################ End of create approver #################


################# Updating to registered of the RFC ticket #################   
update_xml_data "${environment}" "${TICKET_NUMBER}" "Registered" "${username}" "${password}"
################# End of updating to registered of the RFC ticket #################   

################# Update to be approved for implementation of the RFC ticket #################
xml_data=$(cat "/envelops/${environment}/rfc/update.xml")

xml_data=$(echo "$xml_data" | sed -e "s|<change_request>[^<]*</change_request>|<change_request>${TICKET_NUMBER}</change_request>|g")

echo "$xml_data" > "/envelops/${environment}/rfc/update.xml"

bash  "/services/rfc/update_tbafi_rfc_ticket.sh" "${username}" "${password}" "${environment}"
################# end of update to be approved for implementation of the RFC ticket #################

################# get CTask numbers #################
xml_data=$(cat "/envelops/${environment}/rfc/read.xml")

xml_data=$(echo "$xml_data" | sed -e "s|<change_request>[^<]*</change_request>|<change_request>${SYS_ID_RFC}</change_request>|g")

echo "$xml_data" > "/envelops/${environment}/rfc/read.xml"

# here we get 
# <?xml version='1.0' encoding='UTF-8'?>
# <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
# <SOAP-ENV:Body><getKeysResponse xmlns="https://servicenow.dhl.com/ns/change_task/">
# <sys_id>2cdc352197ab71d082c01e800153aff8,50dc352197ab71d082c01e800153aff1,60dc752197ab71d082c01e800153af56</sys_id>
# <count>3</count>
# </getKeysResponse>
# </SOAP-ENV:Body>
# </SOAP-ENV:Envelope>


sys_ids=$(sed -n 's|.*<sys_id>\(.*\)</sys_id>.*|\1|p' "/responses/${environment}/rfc/read_response.xml")

IFS=',' read -r -a sys_ids_arr <<< "$sys_ids"

for sys_id in "${sys_ids_arr[@]}"
do
    echo $sys_id
    ctask_data=$(cat "/envelops/${environment}/ctask/read.xml")
    ctask_data=$(echo "$ctask_data" | sed -e "s|<sys_id>[^<]*</sys_id>|<sys_id>${sys_id}</sys_id>|g")
    echo "$ctask_data" > "/envelops/${environment}/ctask/read.xml"
    # if  <u_task_type>uat</u_task_type> then assign uat_ctask_number to the value inside the <number>*</number>
    # if  <u_task_type>pir</u_task_type> then assign pir_ctask_number to the value inside the <number>*</number>
    # if  <u_task_type>implementation</u_task_type> then assign impl    _ctask_number to the value inside the <number>*</number>
    task_type=$(echo "$ctask_data" | sed -n 's|.*<u_task_type>\(.*\)</u_task_type>.*|\1|p')
    case $task_type in
        "uat")
            uat_ctask_number=$(echo "$ctask_data" | sed -n 's|.*<number>\(.*\)</number>.*|\1|p')
            ;;
        "pir")
            pir_ctask_number=$(echo "$ctask_data" | sed -n 's|.*<number>\(.*\)</number>.*|\1|p')
            ;;
        "implementation")
            impl_ctask_number=$(echo "$ctask_data" | sed -n 's|.*<number>\(.*\)</number>.*|\1|p')
            ;;
    esac

done

echo $uat_ctask_number
echo $pir_ctask_number
echo $impl_ctask_number

################# end of get CTask numbers #################



# xml_data=$(cat "/envelops/${environment}/rfc/update.xml")

# xml_data=$(echo "$xml_data" | sed \
# -e "s|<short_description>[^<]*</short_description>|<short_description>Deploy using FastFRC ${rtp_date}</short_description>|g" \
# -e "s|<description>[^<]*</description>|<description>$6</description>|g" \
# -e "s|<u_requested_by>[^<]*</u_requested_by>|<u_requested_by>$1</u_requested_by>|g" \
# -e "s|<start_date>[^<]*</start_date>|<start_date>${start_date_sec}</start_date>|g" \
# -e "s|<end_date>[^<]*</end_date>|<end_date>${end_date_sec}</end_date>|g" \
# -e "s|<u_customer_rtp_date>[^<]*</u_customer_rtp_date>|<u_customer_rtp_date>${rtp_date}</u_customer_rtp_date>|g")

# echo "$xml_data" > "/envelops/${environment}/rfc/update.xml"

# # update_xml_data "${environment}" "${TICKET_NUMBER}" "Registered" "${username}" "${password}"
# ################# End of updating to registered of the RFC script #################

# ################# Updating to registered of the RFC ticket #################   
# # update_xml_data "${environment}" "${TICKET_NUMBER}" "Tested" "${username}" "${password}"
# ################# End of updating to registered of the RFC script #################

# ################# Updating to closure of the RFC ticket #################   
# xml_data=$(cat "/envelops/${environment}/rfc/close.xml")

# xml_data=$(echo "$xml_data" | sed -e "s|<change_request>[^<]*</change_request>|<change_request>${TICKET_NUMBER}</change_request>|g")

# echo "$xml_data" > "/envelops/${environment}/rfc/close.xml"

# # bash  "/services/rfc/close_rfc_ticket.sh" "${username}" "${password}" "${environment}"

# print_response_envelope_attributes "rfc" "close" "${environment}"
# ################# End of updating to closure of the RFC script #################


################# Printing the output #################
echo -e "$Green Finishing the RFC ticket... $Color_Off"
################# End of printing the output #################
