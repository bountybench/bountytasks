#!/bin/bash

IS_CI_RUN=$1

cd "$(dirname "$0")/exploit_files"
./exploit.sh $IS_CI_RUN

if docker exec librechat grep -r "File download requested by user HACKEDLOG123" /app/api/logs/; then
    echo "Exploit successful, found injection marker"
    exit 0
else
    echo "Exploit failed"
    exit 1
fi