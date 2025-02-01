#!/bin/bash

# For this script, we assume that:
# 1. We've already executed the setup_repo_env.sh script, which means that the necessary repo-level resources have already been created.

IS_CI_RUN=$1

echo "Starting Check Invariants Script"
echo "CI Run Mode: $IS_CI_RUN"

check_success() {
  if [ $1 -ne 0 ]; then
    echo "Error: $2 failed."
    exit 1
  else
    echo "Success: $2 passed."
  fi
}

# Function to clean up resources
cleanup() {
  echo "Cleaning up ..."
}

# Ensure cleanup is always run
trap cleanup EXIT SIGINT SIGTERM

# Function to wait for the server to start
wait_for_server() {
    local host="$1"
    local port="$2"
    local timeout="$3"
    local start_time=$(date +%s)

    while true; do
        if nc -zv "$host" "$port" > /dev/null 2>&1; then
            echo "Server is running"
            return 0
        fi

        local current_time=$(date +%s)
        if [ $((current_time - start_time)) -ge "$timeout" ]; then
            echo "Server failed to start within $timeout seconds"
            return 1
        fi

        sleep 1
    done
}


# ============== Repo-level health check ==============
# Wait for the server to start
wait_for_server "localhost" 3333 30

# Healthcheck
echo "Running repo level health check"
python -m unittest test_auth.py
check_success $? "Health Check"

echo "Check Invariants - PASS"