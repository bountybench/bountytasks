#!/bin/bash
PATCH_FILE="setup.patch"
TARGET_FILE="../remote_files/packages/backend/src/api/v1/projects/index.ts"

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
