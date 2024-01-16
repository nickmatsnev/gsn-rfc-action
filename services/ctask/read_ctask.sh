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

curl -X POST ${URL} \
    --user "$USERNAME:$PASSWORD" \
    -H "Content-Type: text/xml; charset=utf-8" \
    --data-binary @/envelops/${ENV}/ctask/read.xml \
    > "/responses/${ENV}/ctask/read_response.xml"
# response example for uat ctask below:
# <?xml version="1.0" encoding="UTF-8"?>
# <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
#    <SOAP-ENV:Body>
#       <getResponse xmlns="https://servicenow.dhl.com/ns/change_task/">
#          <active>1</active>
#          <activity_due />
#          <additional_assignee_list />
#          <approval>not requested</approval>
#          <approval_set />
#          <assigned_to />
#          <assignment_group>bc7c13bedbed9510f356fad3f39619fc</assignment_group>
#          <business_duration />
#          <business_service />
#          <calendar_duration />
#          <change_request>d4dc712d972f75105eeb33371153af01</change_request>
#          <change_task_type>planning</change_task_type>
#          <close_code />
#          <close_notes />
#          <closed_at />
#          <closed_by />
#          <cmdb_ci />
#          <comments_and_work_notes />
#          <company />
#          <contact_type />
#          <contract />
#          <correlation_display />
#          <correlation_id />
#          <created_from>manual</created_from>
#          <delivery_plan />
#          <delivery_task />
#          <description>Perform UAT</description>
#          <due_date />
#          <escalation>0</escalation>
#          <expected_start />
#          <follow_up />
#          <group_list />
#          <impact>7</impact>
#          <knowledge>0</knowledge>
#          <location />
#          <made_sla>1</made_sla>
#          <number>CTASK4660518</number>
#          <on_hold>0</on_hold>
#          <on_hold_reason />
#          <opened_at>2024-01-05 08:52:31</opened_at>
#          <opened_by>4e419a0e87326000f000675f2b434d58</opened_by>
#          <order>0</order>
#          <parent>d4dc712d972f75105eeb33371153af01</parent>
#          <planned_end_date />
#          <planned_start_date />
#          <priority>4</priority>
#          <reassignment_count>0</reassignment_count>
#          <route_reason>0</route_reason>
#          <service_offering />
#          <short_description>UAT</short_description>
#          <skills />
#          <sla_due />
#          <state>-5</state>
#          <sys_class_name>change_task</sys_class_name>
#          <sys_created_by>tkathirk</sys_created_by>
#          <sys_created_on>2024-01-05 08:52:31</sys_created_on>
#          <sys_domain>global</sys_domain>
#          <sys_id>2cdc352197ab71d082c01e800153aff8</sys_id>
#          <sys_mod_count>0</sys_mod_count>
#          <sys_updated_by>tkathirk</sys_updated_by>
#          <sys_updated_on>2024-01-05 08:52:31</sys_updated_on>
#          <task_effective_number>CTASK4660518</task_effective_number>
#          <time_worked />
#          <u_affected_cis>065e24621b23155c6bab40c69b4bcb3a</u_affected_cis>
#          <u_archive_state>1</u_archive_state>
#          <u_archived>0</u_archived>
#          <u_assigned_at />
#          <u_cause_service />
#          <u_change_stage>build_and_test</u_change_stage>
#          <u_change_template>0</u_change_template>
#          <u_close_code />
#          <u_closure_code>implemented</u_closure_code>
#          <u_customer_satisfaction />
#          <u_date_worked />
#          <u_downtime_duration />
#          <u_downtime_start />
#          <u_dpdhl_email_client_template />
#          <u_dpdhlot_object />
#          <u_e2e_suspended_until />
#          <u_e2e_suspension>0</u_e2e_suspension>
#          <u_effort_service />
#          <u_external_id />
#          <u_external_owners>0</u_external_owners>
#          <u_external_system />
#          <u_flags />
#          <u_impacted_solution />
#          <u_informed_at />
#          <u_lesson_learned />
#          <u_notification_counter>0</u_notification_counter>
#          <u_notification_sent>0</u_notification_sent>
#          <u_preventive_measures />
#          <u_proj_id />
#          <u_report_exclusion />
#          <u_requested_by>4e419a0e87326000f000675f2b434d58</u_requested_by>
#          <u_special_instructions />
#          <u_sw_defect>0</u_sw_defect>
#          <u_task_state>registered</u_task_state>
#          <u_task_type>uat</u_task_type>
#          <u_template />
#          <u_template_oid />
#          <u_time_worked />
#          <u_time_worked_total />
#          <u_vendors />
#          <u_warranty_task />
#          <universal_request />
#          <upon_approval>proceed</upon_approval>
#          <upon_reject>cancel</upon_reject>
#          <urgency>3</urgency>
#          <user_input />
#          <watch_list />
#          <work_end />
#          <work_notes_list />
#          <work_start />
#       </getResponse>
#    </SOAP-ENV:Body>
# </SOAP-ENV:Envelope>