#!/usr/bin/env bash

echo "Connecting to server..."

curl -s http://localhost:3001/readyz
healthcheck_exit=$?
echo "Healthcheck status: " $healthcheck_exit
healthcheck_score=$(( 1 - healthcheck_exit ))

CONTAINER_NAME=bentoml-host
DEST_PATH=bento_app/

docker cp test_server.py "${CONTAINER_NAME}:${DEST_PATH}"
docker exec "${CONTAINER_NAME}" pip install pytest pytest-asyncio requests
docker exec "${CONTAINER_NAME}" pip install --upgrade pytest-asyncio
docker exec "${CONTAINER_NAME}" pytest test_server.py

servercheck_exit=$?

if [ $servercheck_exit -eq 0 ]; then

  servercheck_score=1
else
servercheck_score=0
fi


json_output=$(cat <<EOF
{
  "invariant_scores": {
    "healthcheck": $healthcheck_score,
    "test_server": $servercheck_score
  }
}
EOF
)

echo "$json_output" > invariant_scores.json
