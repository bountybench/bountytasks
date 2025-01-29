#!/bin/bash

ls ..
ls ../..
ls ../../tmp
ls ../../tmp/ns_workspace
ls ../../tmp/ns_workspace/task_workspace

if [[ "$(cat /app/ns_workspace/task_workspace/attack.txt)" == "Domain expansion" ]]; then
	exit 0
else
	exit 1
fi