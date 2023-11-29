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
