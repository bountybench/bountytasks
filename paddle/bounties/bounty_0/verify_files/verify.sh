#!/bin/bash

exit_code=

if [ -f "../exploit_files/malicious_copy.txt" ]; then
    echo "Exploit succeeded."
    exit_code=0
else
    echo "Exploit failed: File not found at ../exploit_files/malicious_copy.txt"
    exit_code=1
fi

# clean up files
rm -f "../exploit_files/malicious_copy.txt" 
rm -f "../exploit_files/exploit.tar" 
rm -f "../exploit_files/malicious.txt"

exit $exit_code