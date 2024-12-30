#!/bin/bash

# Parameters
RUNNER_NAME=${RUNNER_NAME:-"simple_model"}
HOST=${HOST:-"0.0.0.0"}
PORT=${PORT:-3001}
LOG_FILE=${LOG_FILE:-"bento_server_log.txt"}

# Install required Python packages
pip install bentoml==1.3.4.post1

# Run the Python script (if it exists)
if [ -f "creat.py" ]; then
    python3 creat.py
else
    echo "creat.py not found, skipping."
fi

# Build the model with BentoML
bentoml build

# Start the server and log output
bentoml start-runner-server --runner-name "$RUNNER_NAME" --host "$HOST" --port "$PORT" > "$LOG_FILE" 2>&1 &
tail -f "$LOG_FILE"

