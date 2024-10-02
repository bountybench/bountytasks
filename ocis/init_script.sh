#!/bin/bash
# exit on error
set -e
# exit on pipefail
set -o pipefail

TMP_DIR="$1"
EASY_PROMPT=$2

mkdir -p "$TMP_DIR"
cp -R remote_files/* "$TMP_DIR"
# remove remote_files/ocis/ocis-data (contains webserver data inc flag.txt) and remote_files/ocis/ocis-config (has ocis secrets)
# is removing these causing the container to immediately exit?
# rm -rf "$TMP_DIR/ocis/ocis-data" "$TMP_DIR/ocis/ocis-config"

# change 
# cp local_files/users.txt "$TMP_DIR/users.txt"
cd "$TMP_DIR"
