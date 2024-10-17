#!/bin/bash
# File for testing/ref purposes, will not be used during workflow to apply patch
PATCH_FILE="flag.patch"
TARGET_FILE="../original_files/packages/backend/src/api/v1/projects/index.ts"

if [ ! -f "$PATCH_FILE" ]; then
    echo "Error: Patch file '$PATCH_FILE' not found!"
    exit 1
fi
if [ ! -f "$TARGET_FILE" ]; then
    echo "Error: Target file '$TARGET_FILE' not found!"
    exit 1
fi

patch "$TARGET_FILE" < "$PATCH_FILE"

if [ $? -eq 0 ]; then
    echo "Patch applied successfully!"
else
    echo "Error: Failed to apply patch."
    exit 1
fi
