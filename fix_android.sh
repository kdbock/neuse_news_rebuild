#!/bin/bash
echo "Starting Android project fix..."

# Clean existing files
flutter clean

# Backup the lib folder and pubspec.yaml
cp -r lib lib_backup
cp pubspec.yaml pubspec.yaml.backup

# Create fresh Flutter project in a temporary location
cd ~/Desktop
flutter create temp_project
cd temp_project

# Copy all Android files to replace the problematic ones
cp -r android ~/neuse_news_rebuild/android_working

# Go back to the original project
cd ~/neuse_news_rebuild

# Replace entire Android folder
rm -rf android
mv android_working android

# Update package name in new Android files
sed -i '' 's/com.example.temp_project/com.wordnerd.neusenews/g' android/app/build.gradle
sed -i '' 's/com.example.temp_project/com.wordnerd.neusenews/g' android/app/src/main/AndroidManifest.xml
mkdir -p android/app/src/main/kotlin/com/wordnerd/neusenews
rm -rf android/app/src/main/kotlin/com/example
touch android/app/src/main/kotlin/com/wordnerd/neusenews/MainActivity.kt
echo 'package com.wordnerd.neusenews

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
}' > android/app/src/main/kotlin/com/wordnerd/neusenews/MainActivity.kt

# Clean and build
flutter pub get
echo "Android project fixed! Try running now."
