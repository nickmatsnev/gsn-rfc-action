# GSN Automation

## 1. Intro

[Link to source code](https://git.dhl.com/API-Developer-Portal/rfc_service) - feel free to fork and adjust to your own needs.

GSN Automation provides an efficient solution for managing Requests for changes (RFCs). It enables users to create, update, and close GSN RFCs seamlessly, enhancing the workflow in GitHub Actions. It is quite fast, as it takes around a second for the action to perform, thanks to the Bash scripts and WSDL architecture of requests.

## 2. User Guide

### 2.1. GitHub Action

You can integrate GSN Automation into your workflows with the following example:

```yaml
name: Test action

on:
  workflow_call:

jobs:
  test:
    name: Build And Push Image into GCR Dev
    uses: API-Developer-Portal/rfc_service@v3
    with:
      Email: 'nikita.matsnev@dhl.com'
      AssignmentGroup: 'GLOBAL-GROUP-API.SUPPORT.DEVELOPER-PORTAL'
      ApplicationName: 'devportal'
      EscalatedBy: 'saina.bayat@dhl.com'
      ChangeCoordinator: 'ondrej.sztacho@dhl.com'
      Description: 'test rfc gha'
      StartDate: '2023-12-12 10:00:00'
      EndDate: '2023-12-12 11:00:00'
      UatCtaskDescription: 'uat task description'
      ImplCtaskDescription: 'impl task description'
      ApprovalType: 'change_afi'
      WaitFor: 'any'
      RejectHandling: 'reject'
      SlaCategory: '2d'
      Approver: 'nikita.matsnev@dhl.com'
      MaintenanceWindow: 'Inside'
      ImpactedService: 'GROUP API DEVELOPER PORTAL'
      ImpactedBusinessUnit: 'ITS'
      ChangeTested: 'Yes'
      ImplementationRisk: 'Description of impl risk'
      SkipRisk: 'Description of skip risk'
      KnownImpact: 'Known impact description'
      BackoutPlanned: 'Plan of backout'
      BackoutAuthority: 'igor.nemykin@dhl.com'
      BackoutGroups: 'GLOBAL-GROUP-API.SUPPORT.DEVELOPER-PORTAL'
      TriggerForBackout: 'Not deployed'
      DurationOfBackout: '1 minute'
      BackoutPlan: 'description of backout plan'
      SecurityClassification: 'For Internal Use'
      SecurityRegulation: 'No'
      BuildRunActivity: 'BUILD'
      CountryNotified: 'Yes'
      CmdbCi: 'PRG-SOBA-DEVELOPER-PORTAL-APP'
      Username: '${secrets.username}'
      Password: '${secrets.password}'
      Environment: 'uat'

```

### 2.2. Manual usage
 
 For manual operations, use the client.sh script as follows:

```bash
./client.sh create "description" "username" "password"
./client.sh update RFC1234567 "username" "password"
./client.sh close RFC1234567 "username" "password"
```

| Command | Alias | Description | Example                                                             |
|---------|-------|-------------|---------------------------------------------------------------------|
| create  | cr    | create RFC  | ```cr "description" "username" "password" "env"``` or just ```cr``` |
| update  | u     | update RFC  | ```u RFC1234567 "username" "password" "env"```                      |
| close   | cl    | close  RFC  | ```cl RFC1234567 "username" "password" "env"```                     |
| read    | r     | read   RFC  | ```r  RFC1234567 "username" "password" "env"```                     |

## 3. Developer Guide

Developers can handle SOAP requests in services and utilize client.sh for service calls. The GHA client can be injected into the pipeline for streamlined integration. Envelopes for requests and responses are available in the envelops directory.


GHA client can be injected in pipeline.


Envelops are in ```envelops```.

## BPMN of approach when using the manual client

![Architecture](styles/rfcautomated.png)

## BPMN of approach when using the client dedicated for GHA

![Architecture](styles/rfcautomatedGHA.drawio.png)


## Architecture of both approaches

![Architecture](styles/structure.png)
