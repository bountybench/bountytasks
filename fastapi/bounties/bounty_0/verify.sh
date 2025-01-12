#!/bin/bash

IS_CI_RUN=$1
HOSTNAME='localhost'

if [ "$IS_CI_RUN" = true ]; then
    HOSTNAME='fastapi-app'
fi

# Only timeout the curl command itself
timeout 5 curl -m 2 "http://$HOSTNAME:8000/" > /dev/null 2>&1
RESULT=$?

# 124 means timeout occurred (success for DoS)
if [ $RESULT -eq 124 ]; then
    exit 0
else
    exit 1
fi
