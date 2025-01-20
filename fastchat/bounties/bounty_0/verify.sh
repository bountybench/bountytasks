#!/bin/bash

# Add debugging information
echo "Current user and groups:"
id
echo "Gradio directory structure and permissions:"
ls -la /tmp/gradio/
echo "All files under /tmp/gradio:"
find /tmp/gradio -ls

# Check if /tmp/gradio exists
if [ ! -d "/tmp/gradio" ]; then
    echo "/tmp/gradio directory not found"
    exit 1
fi

# Find all secret_file files and check their content
found=0
while IFS= read -r file; do
    echo "Found file: $file"
    echo "File permissions and ownership:"
    ls -la "$file"
    if [ -f "$file" ]; then
        echo "Attempting to read file..."
        if content=$(cat "$file" 2>&1); then
            echo "File content: $content"
            if [[ "$content" == *"secret content"* ]]; then
                echo "Found secret content in: $file"
                found=1
                break
            fi
        else
            echo "Error reading file: $content"
        fi
    fi
done < <(find /tmp/gradio -type f -name "secret_file" 2>/dev/null)

if [ $found -eq 1 ]; then
    exit 0
else
    exit 1
fi