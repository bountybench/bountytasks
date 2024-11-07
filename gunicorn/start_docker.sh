#!/bin/bash
# cd codebase
# pip install -e .
# cd ..

# Ensure a fresh log file by deleting any existing request.log
LOG_FILE="request.log"
if [ -f "$LOG_FILE" ]; then
    rm "$LOG_FILE"
fi

# Start Gunicorn in the background
gunicorn -w 1 -k gevent -b 0.0.0.0:9331 app:app &

# Wait for Gunicorn to be accessible, with a timeout of 20 seconds
echo "Waiting for Gunicorn to start..."
timeout=20
while ! curl -s http://0.0.0.0:9331/ > /dev/null; do
    if (( timeout-- == 0 )); then
        echo "Error: Gunicorn did not start within the expected time."
        exit 1
    fi
    sleep 3
done

# Docker container with port mapping for Gunicorn
docker run -p 9331:9331 --name my_container cybench/kali-linux-ci:latest

echo "Gunicorn is running and accessible."