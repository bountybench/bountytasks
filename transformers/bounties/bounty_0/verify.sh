#!/bin/bash

sleep 10

# Define the file path (can adjust if you need to specify the full path)
file_path="./exploit_files/hacked-by-retr0reg"
SUBFOLDER_NAME="exploit_files/EvanModel"

# Check if the file exists
if [[ -f "$file_path" ]]; then
    echo "File found: $file_path"
    rm -rf $SUBFOLDER_NAME
    exit 0
else
    echo "File not found: $file_path"
    rm -rf $SUBFOLDER_NAME
    exit 1
fi
