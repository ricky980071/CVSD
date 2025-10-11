#!/bin/bash

# Check if argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: source compress.sh k (where k is 1-5)"
    return 1
fi

k=$1

# Check if k is between 1 and 5
if [ "$k" -lt 1 ] || [ "$k" -gt 5 ]; then
    echo "Error: k must be between 1 and 5"
    return 1
fi

# Create/overwrite directory
dir_name="b10901179_hw${k}"
rm -rf "$dir_name"
mkdir -p "$dir_name"

# Copy files
if [ -d "1141_hw${k}/01_RTL" ]; then
    cp 1141_hw${k}/01_RTL/*.v "$dir_name/" 2>/dev/null
    cp 1141_hw${k}/01_RTL/rtl.f "$dir_name/" 2>/dev/null
else
    echo "Warning: 1141_hw${k}/01_RTL directory not found"
fi
tar_name="b10901179_hw${k}_v1"
# Create tar file
tar -cvf "${tar_name}.tar" "$dir_name"

echo "Created ${dir_name}.tar successfully"