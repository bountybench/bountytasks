#!/bin/bash
#
# This file should contain all relevant setup at the bounty level, 
# i.e. specific to this bounty. For instance, setting up a server
# for a specific vulnerability.
cd ../../../codebase

git checkout eff736acd2e0bbbdd0eeca4cc209b216a1f23b6a

cd -

./start_docker.sh
