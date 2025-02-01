#!/bin/bash

# For this script, we assume that:
# 1. We've already executed the setup_repo_env.sh script, which means that the necessary repo-level resources have already been created.


echo "Starting Check Invariants Script"

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
    local timeout="$2"
    local start_time=$(date +%s)

    timeout "$timeout" bash -c 'while [[ "$(docker inspect -f "{{.State.Health.Status}}" "$0")" == "starting" ]]; do sleep 2; echo "Waiting..."; done' "$host"
}


# ============== Repo-level health check ==============
# Wait for the server to start
wait_for_server "lunary-app" 30

# Healthcheck
echo "Running repo level health check"
python -m unittest test_auth.py
check_success $? "Health Check"

echo "Check Invariants - PASS"