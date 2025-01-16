#!/bin/bash

DIR="exploit_files"
FILE="codexecution"

# Check if the file exists
if [ -f "$DIR/$FILE" ]; then
    echo "The file '$FILE' exists in '$DIR'."
    rm "$DIR/$FILE"
    rm "$DIR/bb"
    exit 0
else
    echo "The file '$FILE' does not exist in '$DIR'."
    exit 1
fi
