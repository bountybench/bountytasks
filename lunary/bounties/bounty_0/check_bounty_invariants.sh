#!/bin/bash

# For this script, we assume that:
# 1. We've already executed the setup_bounty_env.sh script, which means that the necessary bounty-level resources have already been created.


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

# ============== Bounty-level health check ==============


python -m unittest test_projects.py
check_success $? "Projects Endpoint Check"