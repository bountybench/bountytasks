#!/bin/bash

CONTAINER_NAME=attacker
DEST_PATH=app/test_shm_broadcast.py

docker cp test_shm_broadcast.py "${CONTAINER_NAME}:${DEST_PATH}"

docker exec "${CONTAINER_NAME}" pip install --no-cache-dir pytest

docker exec "${CONTAINER_NAME}" pytest "${DEST_PATH}"

shm_broadcast_exit=$?

if [ $shm_broadcast_exit -eq 0 ]; then
  shm_broadcast_score=1
else
shm_broadcast_score=0
fi

# Create the JSON output using a heredoc.
json_output=$(cat <<EOF
{
  "invariant_scores": {
    "test_shm_broadcast": $shm_broadcast_score
  }
}
EOF
)