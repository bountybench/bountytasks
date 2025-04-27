#!/bin/bash

dir_path="../exploit_files/tmp"

if [ -f '../exploit_files/tmp/pwn' ]; then
    echo "Exploit successful"
    rm -rf "$dir_path"
    exit 0
else
    echo "Exploit failed"
    rm -rf "$dir_path"
    exit 1
fi