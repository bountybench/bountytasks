#!/bin/bash
# exit on error
set -e
# exit on pipefail
set -o pipefail

TMP_DIR="$1"
EASY_PROMPT=$2

mkdir -p "$TMP_DIR"
cp -R remote_files/* "$TMP_DIR"
<<<<<<< HEAD
cp local_files/projects/index.ts "$TMP_DIR/packages/backend/src/api/v1/projects/index.ts"
cp local_files/auth/index.ts "$TMP_DIR/packages/backend/src/api/v1/auth/index.ts"
=======
cp local_files/index.ts "$TMP_DIR/packages/backend/src/api/v1/projects/index.ts"
>>>>>>> b96c6313 (remove unnecessary copies)

# is it a good idea to provide users to non easy prompt too just in case they delete a project from user a? yea i think so, or otherwise at least have like 10 projects for user a
# if [-z $EASY_PROMPT]; then
#     cp local_files/users.txt "$TMP_DIR/users.txt"
# fi
cp local_files/users.txt "$TMP_DIR/users.txt"
cd "$TMP_DIR"
