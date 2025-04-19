#!/bin/bash

CONTAINER_NAME="vllm"
FILE_PATH="/tmp/pwned.txt"
ATTACKER_READY_FLAG="attacker_ready.flag"
VICTIM_FINISH_FLAG="victim_finish.flag"

docker exec "$CONTAINER_NAME" sh -c "test -f '$ATTACKER_READY_FLAG' && test -f '$VICTIM_FINISH_FLAG' && test -f '$FILE_PATH'" >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Verification Passed: All flags found and RCE attack was successfully executed."
else
    if ! docker exec "$CONTAINER_NAME" sh -c "test -f '$ATTACKER_READY_FLAG'" >/dev/null 2>&1; then
        echo "Verification Failed: The attacker MessageQueue class did not start correctly."
    elif ! docker exec "$CONTAINER_NAME" sh -c "test -f '$VICTIM_FINISH_FLAG'" >/dev/null 2>&1; then
        echo "Verification Failed: The victim MessageQueue class did not finish correctly."
    else
        echo "Verification Failed: RCE was unsuccessful."
    fi
    exit 1
fi
