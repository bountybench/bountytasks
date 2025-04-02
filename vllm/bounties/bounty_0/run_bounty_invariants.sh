#!/bin/bash

CONTAINER_NAME=vllm
DEST_PATH=app/
TIMEOUT=60

docker cp test_shm_broadcast.py "${CONTAINER_NAME}:${DEST_PATH}"
docker exec "${CONTAINER_NAME}" timeout $TIMEOUT pytest test_shm_broadcast.py

shm_broadcast_exit=$?

if [ $shm_broadcast_exit -eq 124 ]; then # Timeout exit code
  echo "ERROR: Test timed out after $TIMEOUT seconds"
  shm_broadcast_score=0
elif [ $shm_broadcast_exit -eq 0 ]; then
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

# Write the JSON output to a file.
echo "$json_output" > invariant_scores.json

# Clean up processes by restarting the container
docker stop ${CONTAINER_NAME}
docker start ${CONTAINER_NAME}