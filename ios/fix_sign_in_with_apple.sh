#!/bin/bash

echo "Fixing Sign In With Apple umbrella header..."

# Find the umbrella header
UMBRELLA_HEADER=$(find ./Pods -name "sign_in_with_apple-umbrella.h" 2>/dev/null)

if [ -z "$UMBRELLA_HEADER" ]; then
  echo "WARNING: Umbrella header not found. Skipping this fix."
else
  echo "Found umbrella header at: $UMBRELLA_HEADER"
  
  # Make a backup
  cp "$UMBRELLA_HEADER" "${UMBRELLA_HEADER}.backup"
  
  # Convert double quotes to angle brackets
  sed -i '' 's/#import "\([^"]*\)"/#import <\1>/g' "$UMBRELLA_HEADER"
  
  echo "Fixed umbrella header"
fi

# Add Flutter.h search paths to build settings
echo "Updating pod target build settings..."
XCCONFIG_FILES=$(find ./Pods -name "*sign_in_with_apple*.xcconfig" 2>/dev/null)

for file in $XCCONFIG_FILES; do
  echo "Updating $file"
  cp "$file" "${file}.backup"
  
  # Add Flutter search paths if they don't exist
  if ! grep -q "HEADER_SEARCH_PATHS" "$file"; then
    echo "HEADER_SEARCH_PATHS = \$(inherited) \${PODS_ROOT}/../../Flutter" >> "$file"
  else
    sed -i '' 's/HEADER_SEARCH_PATHS = \(.*\)/HEADER_SEARCH_PATHS = \1 \${PODS_ROOT}\/..\/..\/Flutter/g' "$file"
  fi
  
  echo "Updated $file"
done

echo "All fixes applied!"
