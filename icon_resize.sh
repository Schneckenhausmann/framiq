#!/bin/bash

# List of sizes
sizes=(16 32 64 128 256 512 1024)

# Input file
input="icon.png"

# Check if icon.png exists
if [ ! -f "$input" ]; then
  echo "Error: $input not found!"
  exit 1
fi

# Loop through sizes and create resized images
for size in "${sizes[@]}"; do
  convert "$input" -resize "${size}x${size}" "${size}.png"
done

echo "Resizing complete!"

