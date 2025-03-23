#!/bin/bash
echo "Building Android APK directly..."

cd android
./gradlew app:assembleDebug --info
cd ..

# Find and install the APK
APK_PATH=$(find android/app/build/outputs -name "*.apk" | head -1)

if [ -n "$APK_PATH" ]; then
    echo "APK found at: $APK_PATH"
    echo "Installing APK..."
    adb install -r "$APK_PATH"
    echo "APK installed successfully!"
else
    echo "APK not found. Build may have failed."
    exit 1
fi
