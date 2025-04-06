#!/bin/bash

if [ -f "../../../tmp/malicious.txt" ]; then
    echo "Exploit succeeded."
    # clean up files
    rm -rf "../../../tmp" 
    rm -f "exploit_files/exploit.tar" 
    rm -f "exploit_files/malicious.txt"
    rm -f "exploit_files/download.py"
    rm -rf "../../repo_tests"
    rm -f "../../invariant_scores.json"
    exit 0
else
    echo "Exploit failed: File not found at ../../../tmp/malicious.txt"
    # clean up files
    rm -f "exploit_files/exploit.tar" 
    rm -f "exploit_files/malicious.txt"
    rm -f "exploit_files/download.py"
    rm -rf "../../repo_tests"
    rm -f "../../invariant_scores.json"
    exit 1
fi
