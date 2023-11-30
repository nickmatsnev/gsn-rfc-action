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

if [ "$#" -ne 11 ]; then
    echo -e "${Yellow} Incorrect number of arguments. Usage: $0 [email] [assignment_group] [u_application_name] [u_escalated_by] [u_change_coordinator] [description] [start_datetime] [end_datetime] [username] [password] [environment] $Color_Off"
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

username=${9}
password=${10}

case "${11}" in
    uat|UAT|Uat) environment="uat" ;;
    prod|PROD|Prod) environment="prod" ;;
    *) echo -e "${Red} Invalid environment. Use UAT or PROD. Current environment is ${11} $Color_Off"; exit 1 ;;
esac

if [ "$start_date_sec" -ge "$end_date_sec" ]; then
    echo -e "${Yellow} The start date must be earlier than the end date. $Color_Off"
    exit 1
fi

echo -e "${Yellow} Starting RFC Ticket creation $Color_Off"
echo -e "${Red} username:${username} , password:${password} $Color_Off"
echo -e "${Red} env:${environment} $Color_Off"
################# End of check if the arguments are set correctly #################


################# Printing the envelope attributes #################
print_envelope_attributes "rfc" "create" "$environment"
################# End of printing the envelope attributes #################


# ################# Modifying ticket for creation as it is set by user in GitHub Actions #################
xml_data=$(cat "/envelops/${environment}/rfc/create.xml")

xml_data=$(echo "$xml_data" | sed \
    -e "s|<short_description>[^<]*</short_description>|<short_description>$6</short_description>|g" \
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

echo -e "$Green Ticket number: $TICKET_NUMBER $Color_Off\n"

if [ -z "$TICKET_NUMBER" ]; then
    echo "No ticket number found in the XML file."
    exit 1
fi
################# End of creating the RFC script #################


################# Create CTask - uat #################


xml_data=$(cat "/envelops/${environment}/ctask/create.xml")

xml_data=$(echo "$xml_data" | sed -e "s|<change_request>[^<]*</change_request>|<change_request>${TICKET_NUMBER}</change_request>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<short_description>[^<]*</short_description>|<short_description>build_and_test task for automated RFC</short_description>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_task_type>[^<]*</u_task_type>|<u_task_type>uat</u_task_type>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_change_stage>[^<]*</u_change_stage>|<u_change_stage>build_and_test</u_change_stage>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<work_start>[^<]*</work_start>|<work_start>${start_date_sec}</work_start>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<work_end>[^<]*</work_end>|<work_end>${end_date_sec}</work_end>|g")
echo "TESTING HERE"
echo "$xml_data" > "/envelops/${environment}/ctask/create.xml"

bash "/services/ctask/create_ctask.sh" "${username}" "${password}" "${environment}"

print_response_envelope_attributes "ctask" "create" "${environment}"

UAT_CTASK_NUMBER=$(sed -n 's|.*<number>\(.*\)</number>.*|\1|p' /responses/${environment}/ctask/create_response.xml)
################# End of creation of CTask - UAT #################


################# Create CTask - implementation #################
# task_type implementation
# u_change_stage implementation

xml_data=$(cat "/envelops/${environment}/ctask/create.xml")

xml_data=$(echo "$xml_data" | sed -e "s|<change_request>[^<]*</change_request>|<change_request>${TICKET_NUMBER}</change_request>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<short_description>[^<]*</short_description>|<short_description>implementation task for automated RFC</short_description>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_task_type>[^<]*</u_task_type>|<u_task_type>implementation</u_task_type>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_change_stage>[^<]*</u_change_stage>|<u_change_stage>implementation</u_change_stage>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<work_start>[^<]*</work_start>|<work_start>${start_date_sec}</work_start>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<work_end>[^<]*</work_end>|<work_end>${end_date_sec}</work_end>|g")

echo "$xml_data" > "/envelops/${environment}/ctask/create.xml"

bash "/services/ctask/create_ctask.sh" "${username}" "${password}" "${environment}"

print_response_envelope_attributes "ctask" "create" "${environment}"

IMPL_CTASK_NUMBER=$(sed -n 's|.*<number>\(.*\)</number>.*|\1|p' /responses/${environment}/ctask/create_response.xml)
################# End of creation of CTask - implementation #################


################# Create group approval #################
xml_data=$(cat "/envelops/${environment}/groupapprove/create.xml")

xml_data=$(echo "$xml_data" | sed -e "s|<change_request>[^<]*</change_request>|<change_request>${TICKET_NUMBER}</change_request>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_approval_type>[^<]*</u_approval_type>|<u_approval_type>change_afi</u_approval_type>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<assignment_group>[^<]*</assignment_group>|<assignment_group>CAB-BIMODAL</assignment_group>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<wait_for>[^<]*</wait_for>|<wait_for>any</wait_for>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<reject_handling>[^<]*</reject_handling>|<reject_handling>reject</reject_handling>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_sla_category>[^<]*</u_sla_category>|<u_sla_category>2d</u_sla_category>|g")

echo "$xml_data" > "/envelops/${environment}/groupapprove/create.xml"

bash "/services/groupapprove/create_group_approval.sh" "${username}" "${password}" "${environment}"
print_response_envelope_attributes "groupapprove" "create" "${environment}"

GAPPR_NUMBER=$(sed -n 's|.*<number>\(.*\)</number>.*|\1|p' /responses/${environment}/groupapprove/create_response.xml)

################# End of creation of group approval #################


################# Create approver #################
xml_data=$(cat "/envelops/${environment}/approver/create.xml")

xml_data=$(echo "$xml_data" | sed -e "s|<sysapproval_group>[^<]*</sysapproval_group>|<sysapproval_group>${GAPPR_NUMBER}</sysapproval_group>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<change_request>[^<]*</change_request>|<change_request>${TICKET_NUMBER}</change_request>|g")

echo "$xml_data" > "/envelops/${environment}/approver/create.xml"

bash "/services/approver/create_approver.sh" "${username}" "${password}" "${environment}"

print_response_envelope_attributes "approver" "create" "${environment}"
################# End of create approver #################

################# Update UAT CTask #################

xml_data=$(cat "/envelops/${environment}/ctask/update.xml")

xml_data=$(echo "$xml_data" | sed -e "s|<change_task>[^<]*</change_task>|<change_task>${UAT_CTASK_NUMBER}</change_task>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<change_request>[^<]*</change_request>|<change_request>${TICKET_NUMBER}</change_request>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<state>[^<]*</state>|<state>1</state>|g")

echo "$xml_data" > "/envelops/${environment}/ctask/update.xml"


bash "/services/ctask/update_ctask.sh" "${username}" "${password}" "${environment}"

print_response_envelope_attributes "ctask" "update" "${environment}"
################# end of Update UAT CTask #################


################# Update Implementation CTask #################
xml_data=$(cat "/envelops/${environment}/ctask/update.xml")

xml_data=$(echo "$xml_data" | sed -e "s|<change_task>[^<]*</change_task>|<change_task>${IMPL_CTASK_NUMBER}</change_task>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<change_request>[^<]*</change_request>|<change_request>${TICKET_NUMBER}</change_request>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<state>[^<]*</state>|<state>1</state>|g")



echo "$xml_data" > "/envelops/${environment}/ctask/update.xml"


bash "/services/ctask/update_ctask.sh" "${username}" "${password}" "${environment}"

print_response_envelope_attributes "ctask" "update" "${environment}"
################# End of update Implementation CTask #################



################# Update UAT CTask #################

xml_data=$(cat "/envelops/${environment}/ctask/update.xml")

xml_data=$(echo "$xml_data" | sed -e "s|<change_task>[^<]*</change_task>|<change_task>${UAT_CTASK_NUMBER}</change_task>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<change_request>[^<]*</change_request>|<change_request>${TICKET_NUMBER}</change_request>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_close_code>[^<]*</u_close_code>|<u_close_code>Implemented</u_close_code>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<close_notes>[^<]*</close_notes>|<close_notes>UAT successfully tested and passed</close_notes>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<state>[^<]*</state>|<state>110</state>|g")

echo "$xml_data" > "/envelops/${environment}/ctask/update.xml"


bash "/services/ctask/update_ctask.sh" "${username}" "${password}" "${environment}"

print_response_envelope_attributes "ctask" "update" "${environment}"
################# end of Update UAT CTask #################


################# Update Implementation CTask #################
xml_data=$(cat "/envelops/${environment}/ctask/update.xml")

xml_data=$(echo "$xml_data" | sed -e "s|<change_task>[^<]*</change_task>|<change_task>${IMPL_CTASK_NUMBER}</change_task>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<change_request>[^<]*</change_request>|<change_request>${TICKET_NUMBER}</change_request>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_close_code>[^<]*</u_close_code>|<u_close_code>Implemented</u_close_code>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<close_notes>[^<]*</close_notes>|<close_notes>Change successfully implemented</close_notes>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<state>[^<]*</state>|<state>110</state>|g")



echo "$xml_data" > "/envelops/${environment}/ctask/update.xml"


bash "/services/ctask/update_ctask.sh" "${username}" "${password}" "${environment}"

print_response_envelope_attributes "ctask" "update" "${environment}"
################# End of update Implementation CTask #################


################# Updating to registered of the RFC ticket #################   
update_xml_data "${environment}" "${TICKET_NUMBER}" "Registered" "${username}" "${password}"
################# End of updating to registered of the RFC script #################

################# Updating to registered of the RFC ticket #################   
# update_xml_data "${environment}" "${TICKET_NUMBER}" "Tested" "${username}" "${password}"
################# End of updating to registered of the RFC script #################

################# Updating to closure of the RFC ticket #################   
xml_data=$(cat "/envelops/${environment}/rfc/close.xml")

xml_data=$(echo "$xml_data" | sed -e "s|<change_request>[^<]*</change_request>|<change_request>${TICKET_NUMBER}</change_request>|g")

echo "$xml_data" > "/envelops/${environment}/rfc/close.xml"

bash  "/services/rfc/close_rfc_ticket.sh" "${username}" "${password}" "${environment}"

print_response_envelope_attributes "rfc" "close" "${environment}"
################# End of updating to closure of the RFC script #################


################# Printing the output #################
echo -e "$Green Finishing the RFC ticket... $Color_Off"
################# End of printing the output #################