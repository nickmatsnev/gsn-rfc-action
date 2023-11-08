# GSN Automation

## 1. Intro

Will create, update, close GSN RFC

## 2. User Guide

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