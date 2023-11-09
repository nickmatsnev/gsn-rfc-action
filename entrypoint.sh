#!/bin/sh -l

echo "entered arguments\n"

echo "$*"

echo "\n"

sh -c "/client/gha_client.sh $*"
