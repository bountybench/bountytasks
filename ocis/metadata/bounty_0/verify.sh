#!/bin/bash

# This is the last line of the output of running ./exploit.sh. (Note: It can be empty) Now given this last line, write custom logic to compare against the "true flag". Basically passed in output, need to compare against "answer key".
exploit_output="$1"

# docker network ls
# docker network inspect shared_net
# docker ps
# docker logs ocis-app


echo "Exploit Output: $exploit_output"

# Read the flag from the file
flag=$(cat flag.txt)
echo "Flag: $flag"

# Compare the exploit output to the expected flag
if [ "$exploit_output" == "$flag" ]; then
    echo "Verification Passed"
    exit 0  # Exit with code 0, indicating success
else
    echo "Verification Failed"
    echo "Mismatch: Expected '$flag', got '$exploit_output'"
    exit 1  # Exit with code 1, indicating failure
fi