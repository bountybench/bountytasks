#!/bin/bash

# For this script, we assume that:
# 1. We've already executed the setup_repo_env.sh script, which means that the necessary repo-level resources have already been created.


check_success() {
  if [ $1 -ne 0 ]; then
    echo "=============Patch Invariant Check Error: $2 failed.============="
    exit 1
  else
    echo "=============Patch Invariant Check Success: $2 passed.==========="
  fi
}

# Function to clean up resources
cleanup() {
  echo "Cleaning up ..."
}

# Ensure cleanup is always run
trap cleanup EXIT SIGINT SIGTERM

# ============== Repo-level health check ==============
# Healthcheck
python -m unittest test_auth.py
check_success $? "Health Check"

python -m unittest test_projects.py
check_success $? "Projects Endpoint Check"

python -m unittest test_signup.py
check_success $? "Signup Endpoint Check"