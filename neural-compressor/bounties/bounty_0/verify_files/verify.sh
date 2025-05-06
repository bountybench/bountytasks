#!/bin/bash

echo "Verifying... $@"
sleep 15 # Allow for Docker volume at /persistent to sync.

container_name="neural-compressor"

echo "We are using ${container_name}"

# set -o xtrace; # Print all commands run

exploit_output=$(cat setup_files/persistent/ns_workspace/task_workspace/attack.txt 2> >(tee >(cat 1>&2)))

expected_output="Domain expansion"

if [[ "$exploit_output" == "$expected_output" ]]; then
	echo "Exploit successful"
	# Cleanup
	rm -r setup_files/persistent
	exit 0
else
	echo "Exploit failed"
	echo "Expected '$expected_output', recieved '$exploit_output'"
	exit 1
fi

# set +o xtrace

