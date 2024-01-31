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

increment_hour() {
    local date_str=$1
    local IFS=" :-"
    read -r year month day hour minute second <<< "$date_str"

    ((hour+=1))

    if [ $hour -gt 24 ]; then
        hour=$((hour - 24))
    fi

    printf "%04d-%02d-%02d %02d:%02d:%02d\n" "$year" "$month" "$day" "$hour" "$minute" "$second"
}
################# End of functions #################

################# Check if the arguments are set correctly #################
requester=${1}
assignment_group=${2}
u_application_name=${3}
u_escalated_by=${4}
u_change_coordinator=${5}
title=${6}
description=${7}
current_datetime=$(date "+%Y-%m-%d %H:%M:%S")
start_date_sec=$(increment_hour "${current_datetime}")
end_date_sec=$(increment_hour "${start_date_sec}")
rtp_date=${start_date_sec%% *}
approver=${8}
template_number=${9}
username=${10}
password=${11}

case "${12}" in
    uat|UAT|Uat) environment="uat" ;;
    prod|PROD|Prod) environment="prod" ;;
    *) echo -e "${Red} Invalid environment. Use UAT or PROD. Current environment is ${environment} $Color_Off"; exit 1 ;;
esac

email_regex="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$"

datetime_regex="^([0-9]{4})-([0-9]{2})-([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})$"

if [ "$#" -ne 12 ]; then
    echo -e "${Yellow} Incorrect number of arguments. Usage: $0 [requester] [assignment_group] [u_application_name] [u_escalated_by] [u_change_coordinator] [title] [description] [approver] [template] [username] [password] [environment] $Color_Off"

    echo -e "${Yellow} You have entered $# parameters $Color_Off"
    exit 1
fi

if [[ ! "${requester}" =~ $email_regex ]]; then
    echo -e "${Yellow} The first argument must be a valid email address. $Color_Off"
    exit 1
fi

if [[ ! "${u_escalated_by}" =~ $email_regex ]]; then
    echo -e "${Yellow} The fourth argument must be a valid email address. $Color_Off"
    exit 1
fi

if [[ ! "${u_change_coordinator}" =~ $email_regex ]]; then
    echo -e "${Yellow} The fifth argument must be a valid email address. $Color_Off"
    exit 1
fi
if ! [[ "$start_date_sec" =~ $datetime_regex ]] || ! [[ "$end_date_sec" =~ $datetime_regex ]]; then
    echo -e "${Yellow} The third and fourth arguments must be in datetime format (YYYY-MM-DD HH:MM:SS). Yours is $start_date_sec and $end_date_sec $Color_Off"
    exit 1
fi

# TODO Add to functions
decrease_hour_by_two() {
    local date_str=$1
    local IFS=" :-"
    read -r year month day hour minute second <<< "$date_str"

    ((hour-=2))

    if [ $hour -lt 0 ]; then
        hour=$((hour + 24))
    fi

    printf "%04d-%02d-%02d %02d:%02d:%02d\n" "$year" "$month" "$day" "$hour" "$minute" "$second"
}

uat_start_date=$(decrease_hour_by_two "${start_date_sec}")
uat_end_date=$(decrease_hour_by_two "${end_date_sec}")

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
    -e "s|<short_description>[^<]*</short_description>|<short_description>${title}</short_description>|g" \
    -e "s|<description>[^<]*</description>|<description>${description}</description>|g" \
    -e "s|<template>[^<]*</template>|<template>${template_number}</template>|g" \
    -e "s|<u_requested_by>[^<]*</u_requested_by>|<u_requested_by>${requester}</u_requested_by>|g" \
    -e "s|<assignment_group>[^<]*</assignment_group>|<assignment_group>${assignment_group}</assignment_group>|g" \
    -e "s|<u_application_name>[^<]*</u_application_name>|<u_application_name>${u_application_name}</u_application_name>|g" \
    -e "s|<u_escalated_by>[^<]*</u_escalated_by>|<u_escalated_by>${u_escalated_by}</u_escalated_by>|g" \
    -e "s|<u_change_coordinator>[^<]*</u_change_coordinator>|<u_change_coordinator>${u_change_coordinator}</u_change_coordinator>|g" \
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
xml_data=$(echo "$xml_data" | sed -e "s|<approver>[^<]*</approver>|<approver>${approver}</approver>|g")

echo "$xml_data" > "/envelops/${environment}/approver/create.xml"

bash "/services/approver/create_approver.sh" "${username}" "${password}" "${environment}"

print_response_envelope_attributes "approver" "create" "${environment}"
################ End of create approver #################

################# Updating to registered of the RFC ticket #################   
update_xml_data "${environment}" "${TICKET_NUMBER}" "Registered" "${username}" "${password}"
################# End of updating to registered of the RFC ticket #################   

################# get CTask numbers #################
xml_data=$(cat "/envelops/${environment}/rfc/read.xml")

xml_data=$(echo "$xml_data" | sed -e "s|<change_request>[^<]*</change_request>|<change_request>${SYS_ID_RFC}</change_request>|g")

echo "$xml_data" > "/envelops/${environment}/rfc/read.xml"

bash "/services/rfc/read_rfc_ticket.sh" "${username}" "${password}" "${environment}"

sys_ids=$(sed -n 's|.*<sys_id>\(.*\)</sys_id>.*|\1|p' "/responses/${environment}/rfc/read_response.xml")

IFS=',' read -r -a sys_ids_arr <<< "$sys_ids"

for sys_id in "${sys_ids_arr[@]}"
do
    echo $sys_id
    ctask_data=$(cat "/envelops/${environment}/ctask/read.xml")
    ctask_data=$(echo "$ctask_data" | sed -e "s|<sys_id>[^<]*</sys_id>|<sys_id>${sys_id}</sys_id>|g")
    echo "$ctask_data" > "/envelops/${environment}/ctask/read.xml"
    bash "/services/ctask/read_ctask.sh" "${username}" "${password}" "${environment}"
    response_data=$(cat "/responses/${environment}/ctask/read_response.xml")
    task_type=$(echo "$response_data" | sed -n 's|.*<u_task_type>\(.*\)</u_task_type>.*|\1|p')
    case $task_type in
        "uat")
            uat_ctask_number=$(echo "$response_data" | sed -n 's|.*<number>\(.*\)</number>.*|\1|p')
            ;;
        "pir")
            pir_ctask_number=$(echo "$response_data" | sed -n 's|.*<number>\(.*\)</number>.*|\1|p')
            ;;
        "implementation")
            impl_ctask_number=$(echo "$response_data" | sed -n 's|.*<number>\(.*\)</number>.*|\1|p')
            ;;
    esac
    print_response_envelope_attributes "ctask" "read" "${environment}"
done

echo $uat_ctask_number
echo $pir_ctask_number
echo $impl_ctask_number

################# end of get CTask numbers #################

# ################# Updating to assigned UAT CTask #################   

xml_data=$(cat "/envelops/${environment}/ctask/update.xml")

xml_data=$(echo "$xml_data" | sed -e "s|<change_task>[^<]*</change_task>|<change_task>${uat_ctask_number}</change_task>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<change_request>[^<]*</change_request>|<change_request>${TICKET_NUMBER}</change_request>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<state>[^<]*</state>|<state>1</state>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<work_end>[^<]*</work_end>|<work_end>${uat_end_date}</work_end>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<work_start>[^<]*</work_start>|<work_start>${uat_start_date}</work_start>|g")

echo "$xml_data" > "/envelops/${environment}/ctask/update.xml"
bash  "/services/ctask/update_ctask.sh" "${username}" "${password}" "${environment}"
print_response_envelope_attributes "ctask" "update" "${environment}"
################# End of updating to assigned UAT CTask #################


################# Updating to completed UAT CTask #################   
xml_data=$(cat "/envelops/${environment}/ctask/update.xml")

xml_data=$(echo "$xml_data" | sed -e "s|<change_task>[^<]*</change_task>|<change_task>${uat_ctask_number}</change_task>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<change_request>[^<]*</change_request>|<change_request>${TICKET_NUMBER}</change_request>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<state>[^<]*</state>|<state>110</state>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<work_end>[^<]*</work_end>|<work_end>${uat_end_date}</work_end>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<work_start>[^<]*</work_start>|<work_start>${uat_start_date}</work_start>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_close_code>[^<]*</u_close_code>|<u_close_code>implemented</u_close_code>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<close_notes>[^<]*</close_notes>|<close_notes>UAT successfully tested and passed</close_notes>|g")

echo "$xml_data" > "/envelops/${environment}/ctask/update.xml"

bash  "/services/ctask/update_ctask.sh" "${username}" "${password}" "${environment}"
print_response_envelope_attributes "ctask" "update" "${environment}"
################# End of updating to assigned UAT CTask #################

################# Updating to RFC to Approved for Implementation #################   
xml_data=$(cat "/envelops/${environment}/rfc/update.xml")

xml_data=$(echo "$xml_data" | sed -e "s|<change_request>[^<]*</change_request>|<change_request>${TICKET_NUMBER}</change_request>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<state>[^<]*</state>|<state> </state>|g")

echo "$xml_data" > "/envelops/${environment}/rfc/update.xml"

bash  "/services/rfc/afi_rfc_ticket.sh" "${username}" "${password}" "${environment}"
print_response_envelope_attributes "rfc" "update" "${environment}"
################# End of Updating to RFC to Approved for Implementation #################   

# ################# Updating to assigned impl CTask #################   

xml_data=$(cat "/envelops/${environment}/ctask/update.xml")

xml_data=$(echo "$xml_data" | sed -e "s|<change_task>[^<]*</change_task>|<change_task>${impl_ctask_number}</change_task>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<change_request>[^<]*</change_request>|<change_request>${TICKET_NUMBER}</change_request>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<state>[^<]*</state>|<state>1</state>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<work_end>[^<]*</work_end>|<work_end>${end_date_sec}</work_end>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<work_start>[^<]*</work_start>|<work_start>${start_date_sec}</work_start>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_close_code>[^<]*</u_close_code>|<u_close_code></u_close_code>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<close_notes>[^<]*</close_notes>|<close_notes></close_notes>|g")

echo "$xml_data" > "/envelops/${environment}/ctask/update.xml"
bash  "/services/ctask/update_ctask.sh" "${username}" "${password}" "${environment}"
print_response_envelope_attributes "ctask" "update" "${environment}"
# ################# End of updating to assigned impl CTask #################

# ################# Updating to completed impl CTask #################   

xml_data=$(cat "/envelops/${environment}/ctask/update.xml")

xml_data=$(echo "$xml_data" | sed -e "s|<change_task>[^<]*</change_task>|<change_task>${impl_ctask_number}</change_task>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<change_request>[^<]*</change_request>|<change_request>${TICKET_NUMBER}</change_request>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<state>[^<]*</state>|<state>110</state>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<work_end>[^<]*</work_end>|<work_end>${end_date_sec}</work_end>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<work_start>[^<]*</work_start>|<work_start>${start_date_sec}</work_start>|g")

xml_data=$(echo "$xml_data" | sed -e "s|<u_close_code>[^<]*</u_close_code>|<u_close_code>implemented</u_close_code>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<close_notes>[^<]*</close_notes>|<close_notes>implementation task has successfully implemented</close_notes>|g")
echo "$xml_data" > "/envelops/${environment}/ctask/update.xml"
bash  "/services/ctask/update_ctask.sh" "${username}" "${password}" "${environment}"
print_response_envelope_attributes "ctask" "update" "${environment}"
# ################# End of updating to in completed impl CTask #################



# ################# Updating to assigned pir CTask #################   

xml_data=$(cat "/envelops/${environment}/ctask/update.xml")

xml_data=$(echo "$xml_data" | sed -e "s|<change_task>[^<]*</change_task>|<change_task>${pir_ctask_number}</change_task>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<change_request>[^<]*</change_request>|<change_request>${TICKET_NUMBER}</change_request>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<state>[^<]*</state>|<state>1</state>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<due_date>[^<]*</due_date>|<due_date> </due_date>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<work_end>[^<]*</work_end>|<work_end> </work_end>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<work_start>[^<]*</work_start>|<work_start> </work_start>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_close_code>[^<]*</u_close_code>|<u_close_code></u_close_code>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<close_notes>[^<]*</close_notes>|<close_notes></close_notes>|g")
echo "$xml_data" > "/envelops/${environment}/ctask/update.xml"
bash  "/services/ctask/update_ctask.sh" "${username}" "${password}" "${environment}"
print_response_envelope_attributes "ctask" "update" "${environment}"
# ################# End of updating to in assigned pir CTask #################

# ################# Updating to completed pir CTask #################   

xml_data=$(cat "/envelops/${environment}/ctask/update.xml")

xml_data=$(echo "$xml_data" | sed -e "s|<change_task>[^<]*</change_task>|<change_task>${pir_ctask_number}</change_task>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<change_request>[^<]*</change_request>|<change_request>${TICKET_NUMBER}</change_request>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<state>[^<]*</state>|<state>110</state>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<due_date>[^<]*</due_date>|<due_date> </due_date>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<work_end>[^<]*</work_end>|<work_end> </work_end>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<work_start>[^<]*</work_start>|<work_start> </work_start>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_close_code>[^<]*</u_close_code>|<u_close_code>implemented</u_close_code>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<close_notes>[^<]*</close_notes>|<close_notes>post implementation review task has successfully implemented and passed</close_notes>|g")
echo "$xml_data" > "/envelops/${environment}/ctask/update.xml"
bash  "/services/ctask/update_ctask.sh" "${username}" "${password}" "${environment}"
print_response_envelope_attributes "ctask" "update" "${environment}"
# ################# End of updating to  completed pir CTask #################

################# Updating to RFC to review for Implementation #################   
# bash  "/services/rfc/review_rfc_ticket.sh" "${username}" "${password}" "${environment}"
# print_response_envelope_attributes "rfc" "update" "${environment}"
################# End of Updating to RFC to Approved for Implementation #################   

################# Updating to RFC to closed #################   
# bash  "/services/rfc/close_rfc_ticket.sh" "${username}" "${password}" "${environment}"
# print_response_envelope_attributes "rfc" "update" "${environment}"
################# End of Updating to RFC to closed #################   

################# Printing the output #################
echo -e "$Green Finishing the RFC ticket... $Color_Off"
################# End of printing the output #################
