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
print_envelope_attributes "create" "$environment"
################# End of printing the envelope attributes #################


# ################# Modifying ticket for creation as it is set by user in GitHub Actions #################
# Step 1

# 1. Create new RFC in “Draft” state by calling the change template.

# 2. Input for below fields must be passed from the interface:

# a. Requested by – the requestor of this change. It is to refer to the sys_user table for active(true) and existing user + make sure to either refer to the UserID or email ID to ensure that the valid and correct user are entered.

# b. Planned Start Date and Planned End Date – this contains the date and time. Planned End Date must be after Planned Start Date. Ensure that the time is rounded. The practice is to use full, half or quarter of an hour

# c. Customer RTP Date – this contains just the date

# d. Scope of the Change – text field with the length of 4000 character, please set the same in the interface as this is something that need to be send from the interface into RFC.

# 3. Create the group approval:

# a. Assigned Group: CAB-BIMODAL

# b. Approval Type: Approval for Implementation

# c. SLA Category: 2 days

# d. “Wait for” and “Handle a rejection by”, it depends on the number of approver that will be approving this change;

# i. If only 1 approver then Wait for = Anyone to approve and Handle a rejection by = Rejecting group approval

# ii. If > then 1 approver then Wait for = Everyone to approve and Handle a rejection by = Waiting for other responses before deciding

# 4. Create the approver into the group approval which had been created in “Not Yet Requested” state. When the approver is created by referencing to a specific group approval and RFC; number of fields will be inherited from the group approval level.

xml_data=$(cat "/envelops/${environment}/create.xml")

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

echo "$xml_data" > "/envelops/${environment}/create.xml"
################# End of modifying ticket for creation as it is set by user in GitHub Actions #################

################# Creating the RFC ticket #################
bash "/services/create_rfc_ticket.sh" "${username}" "${password}" "${environment}"

print_response_envelope_attributes "create" "${environment}"

TICKET_NUMBER=$(sed -n 's|.*<number>\(.*\)</number>.*|\1|p' /responses/${environment}/create_response.xml)

echo -e "$Green Ticket number: $TICKET_NUMBER $Color_Off\n"

if [ -z "$TICKET_NUMBER" ]; then
    echo "No ticket number found in the XML file."
    exit 1
fi
################# End of creating the RFC script #################

################# Updating to closure of the RFC ticket #################
# Step 2

# 1. Update the RFC state from “Draft” to “Registered” and then to “To Be Approved For Implementation”.

# 2. This will automatically set the UAT CTASK state to “Assigned” AND; this will automatically set the group approval state to “Requested” and the approver within it to “Requested” as well.

# 3. Then update the UAT CTASK state to “Completed” with the closure code “Implemented” and close note with the text “UAT successfully tested and passed” AND; Then the approvers state in these group approvals are to be set to “Approved” and this will update the group approval state to “Approved” accordingly.

# 4. Then update the RFC state to “Approved For Implementation”. This will automatically update the implementation CTASK state from “Registered” to “Assigned”.

# 5. Once the implementation result is obtained from interface; if it;

# a) was successful then the implementation CTASK state is to be updated as “Completed” with the closure code “Implemented” and close note with the text “Change successfully implemented”.

# b) Failed then the implementation CTASK state is to be updated as “Completed” with the closure code “Failed” and in the close note the reason for the failure is to be passed from interface.

# 6. Then update the RFC state to “Review”. This will automatically update the “Post Implementation Review” CTASK state from “Registered” to “Assigned”. Next update the Post Implementation Review CTASK:

# a) If change was successful then CTASK state is to be updated as “Completed” with the closure code “Implemented” and close note with the text “Change successfully implemented”.

# b) If change failed then CTASK state is to be updated as “Completed” with the closure code “Failed”. In the close note the question which is in the instruction field are to be passed together with the response to the question. The input for the “Lesson learned” and “Preventive measures” is to be passed from interface as well.

# 7. Then update the RFC state to “Closed” and;

# a) If change was successful then update the closure code as “Successful” and process policy as “Authorized”.

# b) If change failed then update closure code as “Unsuccessful with “Failure Code” and “Failed Change Caused By” passed from interface based on the available choice list of these fields and process policy as “Authorized”.

update_xml_data "${environment}" "${TICKET_NUMBER}" "Registered" "${username}" "${password}"

update_xml_data "${environment}" "${TICKET_NUMBER}" "Approved For Implementation" "${username}" "${password}"

update_xml_data "${environment}" "${TICKET_NUMBER}" "Review" "${username}" "${password}"

update_xml_data "${environment}" "${TICKET_NUMBER}" "Closed" "${username}" "${password}"

################# End of updating to closure of the RFC script #################

################# Printing the output #################
echo -e "$Green Finishing the RFC ticket... $Color_Off"
################# End of printing the output #################
