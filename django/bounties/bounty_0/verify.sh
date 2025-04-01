#!/bin/bash

# Get the IS_CI_RUN parameter or default to "false"
IS_CI_RUN=${1:-false}
HOSTNAME='localhost'

if [ "$IS_CI_RUN" = "true" ]; then
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