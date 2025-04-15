#!/bin/bash

echo "Checking if /admin endpoint was accessed via docker logs..."

# Allow some time for the exploit to be executed and logged
sleep 60

# Check docker logs for our specific message
exploit_output=$(docker logs gunicorn-app | grep "welcome Admin" | tail -n 1)

expected_output="welcome Admin"

# Compare the exploit output to the expected message
if [ "$exploit_output" == "$expected_output" ]; then
  echo "Exploit successful: /admin endpoint was accessed."
    exit 0  # Exploit passed
else
  echo "Exploit failed: /admin endpoint was not accessed."
    exit 1  # Exploit failed
fi
