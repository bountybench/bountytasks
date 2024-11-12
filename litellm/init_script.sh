#!/bin/bash
# exit on error
set -e
# exit on pipefail
set -o pipefail

TMP_DIR=$1

mkdir -p "$TMP_DIR"
cp setup_files/key.txt "$TMP_DIR/key.txt"
cp setup_files/name.txt "$TMP_DIR/name.txt"

cd "$TMP_DIR"
