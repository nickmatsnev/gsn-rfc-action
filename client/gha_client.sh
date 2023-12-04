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

if [ "$start_date_sec" -ge "$end_date_sec" ]; then
    echo -e "${Yellow} The start date must be earlier than the end date. $Color_Off"
    exit 1
fi

echo -e "${Yellow} Starting RFC Ticket creation $Color_Off"
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
xml_data=$(echo "$xml_data" | sed -e "s|<short_description>[^<]*</short_description>|<short_description>${uat_ctask_description}</short_description>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_task_type>[^<]*</u_task_type>|<u_task_type>uat</u_task_type>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_change_stage>[^<]*</u_change_stage>|<u_change_stage>build_and_test</u_change_stage>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<work_start>[^<]*</work_start>|<work_start>${start_date_sec}</work_start>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<work_end>[^<]*</work_end>|<work_end>${end_date_sec}</work_end>|g")

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
xml_data=$(echo "$xml_data" | sed -e "s|<short_description>[^<]*</short_description>|<short_description>${impl_ctask_description}</short_description>|g")
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

xml_data=$(cat "/envelops/${environment}/rfc/update.xml")

xml_data=$(echo "$xml_data" | sed -e "s|<u_maintenance_window>[^<]*</u_maintenance_window>|<u_maintenance_window>${maintenance_window}</u_maintenance_window>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_impacted_service>[^<]*</u_impacted_service>|<u_impacted_service>${impacted_service}</u_impacted_service>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_impacted_business_unit>[^<]*</u_impacted_business_unit>|<u_impacted_business_unit>${impacted_business_unit}</u_impacted_business_unit>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_change_tested>[^<]*</u_change_tested>|<u_change_tested>${change_tested}</u_change_tested>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_implementation_risk>[^<]*</u_implementation_risk>|<u_implementation_risk>${implementation_risk}</u_implementation_risk>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_skip_risk>[^<]*</u_skip_risk>|<u_skip_risk>${skip_risk}</u_skip_risk>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_known_impact>[^<]*</u_known_impact>|<u_known_impact>${known_impact}</u_known_impact>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_backout_planned>[^<]*</u_backout_planned>|<u_backout_planned>${backout_planned}</u_backout_planned>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_backout_authority>[^<]*</u_backout_authority>|<u_backout_authority>${backout_authority}</u_backout_authority>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_backout_groups>[^<]*</u_backout_groups>|<u_backout_groups>${backout_groups}</u_backout_groups>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_trigger_for_backout>[^<]*</u_trigger_for_backout>|<u_trigger_for_backout>${trigger_for_backout}</u_trigger_for_backout>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_duration_of_backout>[^<]*</u_duration_of_backout>|<u_duration_of_backout>${duration_of_backout}</u_duration_of_backout>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<backout_plan>[^<]*</backout_plan>|<backout_plan>${backout_plan}</backout_plan>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_security_classification>[^<]*</u_security_classification>|<u_security_classification>${security_classification}</u_security_classification>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_security_regulation>[^<]*</u_security_regulation>|<u_security_regulation>${security_regulation}</u_security_regulation>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_build_run_activity>[^<]*</u_build_run_activity>|<u_build_run_activity>${build_run_activity}</u_build_run_activity>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<u_country_notified>[^<]*</u_country_notified>|<u_country_notified>${country_notified}</backout_plan>|g")
xml_data=$(echo "$xml_data" | sed -e "s|<cmdb_ci>[^<]*</cmdb_ci>|<cmdb_ci>${cmdb_ci}</cmdb_ci>|g")

echo "$xml_data" > "/envelops/${environment}/rfc/update.xml"

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