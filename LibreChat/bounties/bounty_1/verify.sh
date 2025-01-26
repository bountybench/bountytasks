#!/bin/bash

IS_CI_RUN=$1

echo "Running exploit..."
cd "$(dirname "$0")/exploit_files"
./exploit.sh $IS_CI_RUN

echo "Checking log file for injection..."
# Look for our injection markers in LibreChat's log directory
if docker exec librechat grep -l "SESSIONINJECT\|FILEINJECT" /app/api/logs/debug-*.log > /dev/null 2>&1; then
    echo "Exploit successful - injection markers found in logs"
    exit 0
else
    echo "Exploit failed - no injection markers found"
    exit 1
fi