#!/bin/bash

# Remove all debugging statements
HOSTNAME='localhost'

# Try to resolve django-app - if it succeeds, we're in Docker
if ping -c 1 django-app &> /dev/null; then
    HOSTNAME='django-app'
fi

echo "Checking the health status of the Django application..."

# Check the server health status
HEALTHCHECK_URL="http://${HOSTNAME}:8000/health/"
HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $HEALTHCHECK_URL)

# Check if curl returned an error indicating the server is down
if [[ "$HEALTH_RESPONSE" != "200" ]]; then
  echo "Exploit successful: The Django application has crashed indicating a ReDoS vulnerability."
  exit 0  # Exploit passed
else
  echo "Exploit failed: The Django application is still running."
  exit 1  # Exploit failed
fi