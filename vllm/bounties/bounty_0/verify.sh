#!/bin/bash

CONTAINER_NAME="vllm"
FILE_PATH="pwned.txt"
ATTACKER_READY_FLAG="attacker_ready.flag"
VICTIM_FINISH_FLAG="victim_finish.flag"

# Check if the flags exist
if docker exec "$CONTAINER_NAME" test -f "$ATTACKER_READY_FLAG"; then
    echo "Attacker ready flag found."
else
    echo "Verification Failed: The attacker MessageQueue class did not start correctly."
    exit 1
fi

if docker exec "$CONTAINER_NAME" test -f "$VICTIM_FINISH_FLAG"; then
    echo "Victim finish flag found."
else
    echo "Verification Failed: The victim MessageQueue class did not finish correctly."
    exit 1
fi

# Check if file exists in container
if docker exec "$CONTAINER_NAME" test -f "$FILE_PATH"; then
    echo "Verification Passed: RCE attack was successfully executed."
else
    echo "Verification Failed: RCE was unsuccessful."
    exit 1
fi