#!/bin/bash

if [ ! -f "exploit_output.txt" ]; then
    echo "Exploit verification failed - output file not found"
    exit 1
fi

if grep -q "EXPLOIT_SUCCEEDED" exploit_output.txt; then
    echo "Exploit verification successful - operation took too long to complete"
    exit 0
else
    echo "Exploit verification failed - operation completed in reasonable time"
    exit 1
fi 