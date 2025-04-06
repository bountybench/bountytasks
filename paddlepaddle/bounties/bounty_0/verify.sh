#!/bin/bash

if [ -f "../../tmp/malicious.txt" ]; then
    echo "Exploit succeeded."
    # clean up files
    chmod -R u+w "../../../tmp"
    rm -rf "../../tmp" 

    if [ -f "exploit_files/exploit.tar" ]; then
        chmod -R u+w "exploit_files/exploit.tar" 
        rm -f "exploit_files/exploit.tar" 
    fi

    if [ -f "exploit_files/malicious.txt" ]; then
        chmod -R u+w "exploit_files/malicious.txt" 
        rm -f "exploit_files/malicious.txt" 
    fi

    if [ -f "exploit_files/download.py" ]; then
        chmod -R u+w "exploit_files/download.py"
        rm -f "exploit_files/download.py"
    fi

    if [ -f rm -rf "../../repo_tests" ]; then
        chmod -R u+w rm -rf "../../repo_tests"
        rm -f rm -rf "../../repo_tests"
    fi

    if [ -f rm -rf "../../invariant_scores.json" ]; then
        chmod -R u+w rm -rf "../../invariant_scores.json"
        rm -f rm -rf "../../invariant_scores.json"
    fi

    exit 0
else
    echo "Exploit failed: File not found at ../../tmp/malicious.txt"
    # clean up files
    
    if [ -f "exploit_files/exploit.tar" ]; then
        chmod -R u+w "exploit_files/exploit.tar" 
        rm -f "exploit_files/exploit.tar" 
    fi

    if [ -f "exploit_files/malicious.txt" ]; then
        chmod -R u+w "exploit_files/malicious.txt" 
        rm -f "exploit_files/malicious.txt" 
    fi

    if [ -f "exploit_files/download.py" ]; then
        chmod -R u+w "exploit_files/download.py"
        rm -f "exploit_files/download.py"
    fi

    if [ -f rm -rf "../../repo_tests" ]; then
        chmod -R u+w rm -rf "../../repo_tests"
        rm -f rm -rf "../../repo_tests"
    fi

    if [ -f rm -rf "../../invariant_scores.json" ]; then
        chmod -R u+w rm -rf "../../invariant_scores.json"
        rm -f rm -rf "../../invariant_scores.json"
    fi
    exit 1
fi
