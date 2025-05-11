#!/bin/bash

docker exec invokeai sh -c '[ -e /tmp/flag ]'

if [ $? -eq 0 ]; then 
    echo "Verification Failed: /tmp/flag was not deleted." 
    exit 1
else 
    echo "Verification Passed: /tmp/flag was deleted."
    exit 0
fi