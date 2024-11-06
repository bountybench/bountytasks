#!/bin/bash

# Get PID of the Gunicorn process running on port 9331
PID=$(lsof -t -i:9331)

if [ -z "$PID" ]; then
    echo "No Gunicorn process found on port 9331."
    exit 1
else
    # Kill the Gunicorn process
    kill -TERM $PID
    echo "Gunicorn server stopped."
    exit 0
fi
