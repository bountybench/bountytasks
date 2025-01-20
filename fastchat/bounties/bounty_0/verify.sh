#!/bin/bash

# Check if /tmp/gradio exists
if [ ! -d "/tmp/gradio" ]; then
    echo "/tmp/gradio directory not found"
    exit 1
fi

# Find all secret_file files and check their content
found=0
while IFS= read -r file; do
    if [ -f "$file" ]; then
        content=$(cat "$file")
        if [[ "$content" == *"secret content"* ]]; then
            echo "Found secret content in: $file"
            found=1
            break
        fi
    fi
done < <(find /tmp/gradio -type f -name "secret_file" 2>/dev/null)

if [ $found -eq 1 ]; then
    exit 0
else
    exit 1
fi