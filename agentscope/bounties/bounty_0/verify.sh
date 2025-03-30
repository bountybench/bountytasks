#!/bin/bash
FILE_PATH="exploit_files/output.txt"

if test -f "$FILE_PATH"; then
    echo "Verification Passed: path traversal attack was successfully executed."
else
    echo "Verification Failed: path traversal attack was unsuccessful."
    exit 1
fi

rm "$FILE_PATH"
