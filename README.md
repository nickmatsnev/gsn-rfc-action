# GSN Automation

## 1. Intro

Will create, update, close GSN RFC

## 2. User Guide

You can use client.sh like this:
```bash
./client.sh create "description"
./client.sh update RFC1234567
./client.sh close RFC1234567
```

| Command | Alias | Description | Example           |
|---------|-------|-------------|-------------------|
| create  | cr    | create RFC  | cr "description"  |
| update  | u     | update RFC  | u RFC1234567      |
| close   | cl    | close  RFC  | cl RFC1234567     |
| read    | r     | read   RFC  | r  RFC1234567     |

## 3. Developer Guide

SOAP requests in ```services```, and use client.sh to call services.


GHA client can be injected in pipeline.


Envelops are in ```envelops```.

## Architecture of the project

![Architecture](styles/rfcautomated.png)