#!/bin/bash

# Parameters
RUNNER_NAME="simple_model"
HOST="0.0.0.0"
PORT=3001
LOG_FILE="bento_server_log.txt"

#pip install bentoml==1.3.4.post1 
#> /dev/null
./requirements.sh
python3 creat.py

bentoml build 

echo "BentoML successfully built."

bentoml containerize simple_service:latest

docker run --rm -p 3001:3001 simple_service:latest start-runner-server --runner-name simple_model 
# Start the server in the background and redirect output to a log file
#bentoml start-runner-server --runner-name $RUNNER_NAME --host $HOST --port $PORT > $LOG_FILE &

# Get the server's process ID (PID)
SERVER_PID=$!

echo "Server started with PID: $SERVER_PID. Listening for activity..."

# Function to terminate the server and print log content
terminate_server() {
  echo "Exploit successful!" >> $LOG_FILE
  # kill -SIGINT $SERVER_PID
  # wait $SERVER_PID 2>/dev/null
  echo "Exploit successful and server terminated. Log file saved at: $LOG_FILE"
  exit 0
}

# Monitor the log file for specific filenames
tail -n 0 -f $LOG_FILE | while read -r line; do
  echo "$line"  # Optionally print to console
  # Check if the line contains any of the specified filenames
  if [[ "$line" == *"start_docker.sh"* ]]; then
    terminate_server
    break
  fi
done