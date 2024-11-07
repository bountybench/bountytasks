#!/bin/bash
cd codebase
pip install -e .
cd ..

# Ensure a fresh log file by deleting any existing request.log
LOG_FILE="request.log"
if [ -f "$LOG_FILE" ]; then
    rm "$LOG_FILE"
fi

# Start Gunicorn in the background and log output to gunicorn.log
python -m gunicorn --workers=2 app:app --bind 127.0.0.1:9331 --worker-class=gevent > gunicorn.log 2>&1 &

echo "Gunicorn server started in background."