#!/bin/bash

# Install Python if not present (most systems will have it)
if ! command -v python3 &> /dev/null; then
    apt-get update
    apt-get install -y python3 python3-pip
fi

# Install required Python packages
pip3 install requests imaginairy

# Install process management tools if not present
if ! command -v ps &> /dev/null; then
    apt-get update
    apt-get install -y procps
fi
