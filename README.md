# Hera - GSN Automation

## 1. Intro

[Link to source code](https://git.dhl.com/API-Developer-Portal/rfc_service) - feel free to fork and adjust to your own needs.

GSN Automation provides an efficient solution for managing Requests for changes (RFCs). It enables users to create, update, and close GSN RFCs seamlessly, enhancing the workflow in GitHub Actions. It is quite fast, as it takes around a second for the action to perform, thanks to the Bash scripts and WSDL architecture of requests.

Named after the Greek goddess Hera, this service brings together the API Developer Portal and ServiceNow smoothly and efficiently. It's like a bridge that makes working between these two systems easy and straightforward. Just like Hera united different worlds, this project connects these important tools in a simple, yet powerful way.

## 2. User Guide

### 2.1. GitHub Action

You can integrate GSN Automation into your workflows with the following example:

```yaml
name: Test action

on:
  workflow_call:
jobs:
  autorfc:
    name: Create RFC
    uses: API-Developer-Portal/rfc_service@v5
    with:
      Email: 'name.surname@dhl.com'
      AssignmentGroup: 'CAB-BIMODAL'
      ApplicationName: 'appname'
      EscalatedBy: 'name.surname@dhl.com'
      ChangeCoordinator: 'name.surname@dhl.com'
      Title: 'deploy vx.x.x'
      Description: 'test rfc gha'
      Approver: 'gsn_test@dhl.com'
      Template: 'RFCXXXXXXX'
      Username: '${secrets.username}'
      Password: '${secrets.password}'
      Environment: 'uat'
      Date: '24-04-2024 10:00:00'
```

### 2.2. Manual usage
 
 For manual operations, use the client.sh script as follows:

```bash
./client.sh create "folder" "number" "description" "username" "password" "env"
./client.sh update "folder" "number"  "username" "password" "env"
./client.sh close "folder" "number"  "username" "password" "env"
```

| Command | Alias | Description | Example                                                     |
|---------|-------|-------------|-------------------------------------------------------------|
| create  | cr    | create RFC  | ```cr "folder" "description" "username" "password" "env"``` |
| update  | u     | update RFC  | ```u "folder"  "number" "username" "password" "env"```      |
| close   | cl    | close  RFC  | ```cl "folder"  "number" "username" "password" "env"```     |
| read    | r     | read   RFC  | ```r  "folder" "number" "username" "password" "env"```      |


It is also important to change the content of the envelops per your choosing. There is a native automated selector which helps you to prefill the envelops through CLI, but if your requests are similar in their content, you can save the data in envelops and deactivate editing fields and add some script to only edit the desired field. Generally this is a handful sandbox with many possibilities and it wants **you** to extend it! Do not hesitate to fork the project and dive in and adjust the service as you wish, since it provides great SOAP CRUD capabilities for other GSN services, and not just GSN. I am planning to add custom environments, origins and endpoints, so you will be free to automate any process which involves SOAP!  


#### What entities are available for operations?

* Request for Change
* Ctasks
* Group approvals
* Approvers

## 3. Developer Guide

### 3.1. Introduction

Developers can handle SOAP requests in services and utilize `client.sh` for service calls. The GHA client can be injected into the pipeline for streamlined integration. Envelopes for requests and responses are available in the envelops directory.

Main idea is preserved in `gha_client.sh`, while `client.sh` is serving mainly for manual creation and can/should be used for fast runs of Change Event SOAP API.

### 3.2. Process in details

You can find it at [Process section](./Process.md)

 
### 3.3. Structure of the project

GHA client can be injected in pipeline or can be started as an independent workflow with inputs triggered by workflow dispatch(user interaction).

Envelops are in ```envelops```.

## BPMN of approach when using the manual client

![Architecture](styles/rfcautomated.png)

## BPMN of approach when using the client dedicated for GHA

![Architecture](styles/rfcautomatedGHA.drawio.png)


## Architecture

![Architecture](styles/structure.png)


## Timeline
![autorfc_timeline](https://media.git.dhl.com/user/15023/files/8a77f85b-d5e3-4f0b-8cf2-b8890551635e)



## Example of flow in GAPI Developer Portal
![PortalGSNFlow](https://media.git.dhl.com/user/15023/files/eebc54f4-d760-4a78-9aae-cedda02c0078)
