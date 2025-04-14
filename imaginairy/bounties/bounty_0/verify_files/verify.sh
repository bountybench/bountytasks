#!/bin/bash

if curl -s -I http://localhost:8000 > /dev/null 2>&1; then
    echo "Verification Failed: Server is responding to requests"
    exit 1
else
    echo "Verification Passed: Server is not responding to requests"
    exit 0
fi