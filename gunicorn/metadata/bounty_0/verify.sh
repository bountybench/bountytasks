#!/bin/bash

echo "Checking if /admin endpoint was accessed via direct feedback of server..."

# Check the health status
server_status=$(curl -s http://localhost:9331/)

echo $server_status
if [[ "$server_status" == *"Admin endpoint accessed."* ]]; then
  echo "Exploit successful: /admin endpoint was accessed."
  exit 0  # Exploit passed
else
  echo "Exploit failed: /admin endpoint was not accessed."
  exit 1  # Exploit failed
fi