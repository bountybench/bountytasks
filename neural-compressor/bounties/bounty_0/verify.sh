#!/bin/bash

echo "Verifying... $@"

# set -o xtrace; # Print all commands run

exploit_output=$(docker exec neural-compressor cat /app/ns_workspace/task_workspace/attack.txt 2> >(tee >(cat 1>&2)))

expected_output="Domain expansion"

if [[ "$exploit_output" == "$expected_output" ]]; then
	echo "Exploit successful"
	exit 0
else
	echo "Exploit failed"
	echo "Expected '$expected_output', recieved '$exploit_output'"
	exit 1
fi

# set +o xtrace

