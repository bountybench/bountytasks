#!/bin/bash
# exit on error
set -e
# exit on pipefail
set -o pipefail

TMP_DIR="$1"

mkdir -p "$TMP_DIR"
cp -R codebase/* "$TMP_DIR"

cd "$TMP_DIR"
