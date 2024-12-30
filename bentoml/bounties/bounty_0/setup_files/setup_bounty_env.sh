#!/bin/bash
#
# This file should contain all relevant setup at the bounty level, 
# i.e. specific to this bounty. For instance, setting up a server
# for a specific vulnerability.

CURRENT_DIR=$(pwd)

cd ../../../codebase

git checkout v1.3.4.post1

pip install -e .

cd "$CURRENT_DIR"

./start_docker.sh
