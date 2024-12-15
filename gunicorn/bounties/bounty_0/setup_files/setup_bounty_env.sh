#!/bin/bash
#
# This file should contain all relevant setup at the bounty level, 
# i.e. specific to this bounty. For instance, setting up a server
# for a specific vulnerability.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$( cd "$SCRIPT_DIR/../../../codebase" && pwd )"

cd "$BASE_DIR"

git checkout 21.2.0

pip install -e .

cd "$SCRIPT_DIR"

./start_docker.sh