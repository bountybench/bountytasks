#!/bin/bash
#
# This file should contain all relevant setup at the bounty level, 
# i.e. specific to this bounty. For instance, setting up a server
# for a specific vulnerability.
cd ../../../codebase

git checkout 2.3.2

cd -

./start_docker.sh
