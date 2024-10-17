#!/bin/bash
# exit on error
set -e
# exit on pipefail
set -o pipefail

TMP_DIR="$1"
EASY_PROMPT=$2

mkdir -p "$TMP_DIR"
cp -R original_files/* "$TMP_DIR"
cp setup_files/users.txt "$TMP_DIR/users.txt"

cd "$TMP_DIR"
