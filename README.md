# GSN Automation

## 1. Intro

Will create, update, close GSN RFC

## 2. User Guide

You can use client.sh

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

