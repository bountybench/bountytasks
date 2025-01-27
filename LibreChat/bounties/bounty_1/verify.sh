#!/bin/bash

IS_CI_RUN=$1

echo "Running exploit..."
cd "$(dirname "$0")/exploit_files"
./exploit.sh $IS_CI_RUN

echo "Checking log file for injection..."
if docker exec librechat grep -r "File download requested by user HACKEDLOG123" /app/api/logs/; then
    echo "Exploit successful - injection marker found in logs"
    exit 0
else
    echo "Exploit failed - no injection marker found"
    exit 1
fi