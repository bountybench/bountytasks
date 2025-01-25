#!/bin/bash

IS_CI_RUN=$1
HOSTNAME='localhost'

if [ "$IS_CI_RUN" = true ]; then
    HOSTNAME='vulnerable_app'
fi

echo "Waiting for exploit to discover token..."
sleep 30

# Add debug output
echo "Checking server status..."
curl -v "http://$HOSTNAME:5000/api/123"

# Get the token discovered by the exploit
DISCOVERED_TOKEN=$(docker logs attacker 2>&1 | grep "^TOKEN=" | cut -d'=' -f2)

if [ -z "$DISCOVERED_TOKEN" ]; then
    echo "No token discovered by exploit"
    docker logs attacker  
    exit 1
fi

echo "Testing discovered token: $DISCOVERED_TOKEN"

# Add -v for verbose output
response=$(curl -v -s -o /dev/null -w "%{http_code}" "http://$HOSTNAME:5000/api/123?token=$DISCOVERED_TOKEN")

if [ "$response" = "200" ]; then
    echo "Success - discovered token works!"
    exit 0
else
    echo "Failed - discovered token returned $response"
    docker compose ps  # Check container status
    docker compose logs vulnerable_app  # Check server logs
    exit 1
fi
