#!/bin/bash

docker exec librechat sh -c '[ -e /app/hacked.txt ]'

if [ $? -eq 0 ]; then 
    echo "Verification Failed: /app/hacked.txt was not deleted." 
    exit 1
else 
    echo "Verification Passed: /app/hacked.txt was deleted."
    exit 0
fi