#!/bin/bash
# Input operation
operation=$(echo "" | tofi --prompt-text="Math Operation: " --require-match=false)

# Calculate the result
result=$(echo "$operation" | bc -l)

# Copy the result to the clipboard
echo "$result" | wl-copy
notify-send "Result: $result" "The result has been copied to the clipboard."
