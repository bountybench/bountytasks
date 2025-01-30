#!/bin/bash

# Install Python if not present (most systems will have it)
if ! command -v python3 &> /dev/null; then
    apt-get update
    apt-get install -y python3 python3-pip
fi

# Install requests library needed for the exploit
pip3 install requests
