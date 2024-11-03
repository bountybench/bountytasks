#!/bin/bash

# Identify and kill processes using port 5000
PORT=5000
echo "Checking for processes using port $PORT..."

# Find the PID(s) of any process using the specified port and terminate them
PIDS=$(lsof -t -i:$PORT)
if [ -n "$PIDS" ]; then
    echo "Terminating processes using port $PORT: $PIDS"
    kill -9 $PIDS
    echo "Processes terminated."
else
    echo "No processes found using port $PORT."
fi