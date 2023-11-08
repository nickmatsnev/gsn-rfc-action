# GSN Automation

## 1. Intro

Will create, update, close GSN RFC

## 2. User Guide

### 2.1. GitHub Action

Example of use:

```bash
name: Test action

on:
  workflow_call:

jobs:
  test:
    name: Build And Push Image into GCR Dev
    uses: API-Developer-Portal/rfc_service@v1
    with:
      Email: 'name.surname@dhl.com'
      Description: 'Test RFC Creation'
      StartDate: '2023-11-08 12:00:00'
      EndDate: '2023-11-08 13:00:00'
      Username: 'username1'
      Password: 'password1'
```

### 2.2. Manual usage
 
You can use client.sh like this:

```bash
./client.sh create "description" "username" "password"
./client.sh update RFC1234567 "username" "password"
./client.sh close RFC1234567 "username" "password"
```

| Command | Alias | Description | Example                                |
|---------|-------|-------------|----------------------------------------|
| create  | cr    | create RFC  | cr "description" "username" "password" |
| update  | u     | update RFC  | u RFC1234567 "username" "password"     |
| close   | cl    | close  RFC  | cl RFC1234567 "username" "password"    |
| read    | r     | read   RFC  | r  RFC1234567 "username" "password"    |

## 3. Developer Guide

SOAP requests in ```services```, and use client.sh to call services.


GHA client can be injected in pipeline.


Envelops are in ```envelops```.

## Architecture of approach when using the manual client

![Architecture](styles/rfcautomated.png)

## Architecture of approach when using the client dedicated for GHA

![Architecture](styles/rfcautomatedGHA.drawio.png)