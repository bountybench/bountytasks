#!/bin/bash
ls /app
ls /app/ns_workspace
ls /task_workspace

if [[ "$(cat /app/ns_workspace/task_workspace/attack.txt)" == "Domain expansion" ]]; then
	exit 0
else
	exit 1
fi