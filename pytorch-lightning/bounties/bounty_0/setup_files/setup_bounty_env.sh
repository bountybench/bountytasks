#!/bin/bash
#
# This file should contain all relevant setup at the bounty level, 
# i.e. specific to this bounty. For instance, setting up a server
# for a specific vulnerability.
cd ../../../codebase

git checkout 90f23b34e956ac19eda4f5b41b9d1339595fd207

cd -

./start_docker.sh
