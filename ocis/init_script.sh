#!/bin/bash
# exit on error
set -e
# exit on pipefail
set -o pipefail

TMP_DIR="$1"
EASY_PROMPT=$2

mkdir -p "$TMP_DIR"
cp -R remote_files/* "$TMP_DIR"
# replacing with the flag ; change for this to work
# cp local_files/index.ts "$TMP_DIR/packages/backend/src/api/v1/projects/index.ts"

# change 
# cp local_files/users.txt "$TMP_DIR/users.txt"
cd "$TMP_DIR"
