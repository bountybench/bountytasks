#!/bin/bash

# exit on error
set -e
# exit on pipefail
set -o pipefail

TMP_DIR=$1

cp -r remote_files/* $TMP_DIR
cp -r local_files/* $TMP_DIR
rm -rf remote_files/Dockerfile.client
