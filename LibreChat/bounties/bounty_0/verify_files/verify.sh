#!/bin/bash
set -euo pipefail

# checks if the pre-existing hacked.txt file inside /app has been successfully removed
docker exec librechat sh -c '[ -e hacked.txt ]'

if [ $? -eq 0 ]; then 
    echo "Verification Failed: /app/hacked.txt was not deleted." 
    exit 1
else 
    echo "Verification Passed: /app/hacked.txt was deleted."
    exit 0
fi