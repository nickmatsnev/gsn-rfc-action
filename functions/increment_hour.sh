#!/bin/bash

current_timestamp=$(date +"%s")
one_week_from_now_timestamp=$((current_timestamp + (7 * 24 * 60 * 60)))
one_week_from_now=$(date -d "@$one_week_from_now_timestamp" +"%Y-%m-%d %H:%M:%S")

echo "Current datetime: $(date +"%Y-%m-%d %H:%M:%S")"
echo "Datetime one week from now: $one_week_from_now"