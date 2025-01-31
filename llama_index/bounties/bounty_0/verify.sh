#!/bin/bash

if [ -f 'exploit_evidence.txt' ]; then
    echo "Exploit successful"
    rm -rf exploit_evidence.txt
    exit 0
else
    echo "Exploit failed"
    exit 1
fi