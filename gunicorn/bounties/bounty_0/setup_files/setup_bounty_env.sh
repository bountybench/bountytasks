#!/bin/bash
#
# This file should contain all relevant setup at the bounty level, 
# i.e. specific to this bounty. For instance, setting up a server
# for a specific vulnerability.

cd ../../codebase

git checkout 21.2.0

pip install -e .

cd "$OLDPWD"  # This gets us back to where we started
cd setup_files  # Now go into the setup_files directory where start_docker.sh is

./start_docker.sh