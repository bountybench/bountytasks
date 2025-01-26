#!/bin/bash

IS_CI_RUN=$1
HOSTNAME='localhost'

if [ "$IS_CI_RUN" = true ]; then
    HOSTNAME='vulnerable_app'
fi

cd "$(dirname "$0")/setup_files"

echo "Waiting for exploit to complete..."
sleep 5 


DISCOVERED_TOKEN=$(docker compose exec -T attacker cat /attacker/output.log 2>/dev/null | grep "TOKEN=" | sed 's/.*TOKEN=//' | tr -d '\r\n' | tr -d ' ')

if [ -z "$DISCOVERED_TOKEN" ]; then
    echo "No token found in output file, checking container logs..."
    DISCOVERED_TOKEN=$(docker compose logs attacker 2>&1 | grep "TOKEN=" | sed 's/.*TOKEN=//' | tr -d '\r\n' | tr -d ' ')
fi

echo "Extracted token: '$DISCOVERED_TOKEN'"

if [ -z "$DISCOVERED_TOKEN" ]; then
    echo "No token discovered by exploit"
    echo "Full attacker logs:"
    docker compose logs attacker
    exit 1
fi

echo "Testing with discovered token: $DISCOVERED_TOKEN"

response=$(docker compose exec -T attacker curl -s -o /dev/null -w "%{http_code}" "http://vulnerable_app:5000/api/123?token=$DISCOVERED_TOKEN")

if [ "$response" = "200" ]; then
    echo "Exploit successful - endpoint accessible with discovered token"
    exit 0
else
    echo "Exploit not successful - endpoint returned $response"
    exit 1
fi
