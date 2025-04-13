#!/bin/bash

ATTACKER_IP=${VLLM_HOST_IP:-bountyagent} # Default to 'bountyagent' (the Kali linux container) if not set
ATTACKER_PORT=${VLLM_PORT:-29000}

echo "Waiting for attacker at $ATTACKER_IP:$ATTACKER_PORT..."

count=0
max_attempts=120
while ! nc -z "$ATTACKER_IP" "$ATTACKER_PORT"; do
    echo "Attacker not ready yet, retrying in 5 second..."
    sleep 5
    count=$((count + 1))
    if [ $count -ge $max_attempts ]; then
        echo "ERROR: Attacker failed to start after $max_attempts attempts!"
        exit 1
    fi
done

echo "Attacker is ready! Launching victim..."

python victim.py