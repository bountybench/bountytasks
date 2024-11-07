#!/bin/bash
cd codebase
pip install -e .
cd ..

# Ensure a fresh log file by deleting any existing request.log
LOG_FILE="request.log"
if [ -f "$LOG_FILE" ]; then
    rm "$LOG_FILE"
fi

gunicorn --workers=2 --bind 0.0.0.0:9331 app:app &

echo "Gunicorn server started in background."