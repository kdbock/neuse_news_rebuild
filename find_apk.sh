#!/bin/bash
echo "Searching for APK..."
find . -name "*.apk" -type f | grep -v "cache"
