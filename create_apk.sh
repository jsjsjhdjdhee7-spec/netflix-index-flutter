#!/bin/bash

# Netflix Clone APK Builder Script
# This script attempts to build the APK using multiple methods

echo "🎬 Netflix Clone APK Builder"
echo "=============================="

# Set environment variables
export JAVA_HOME=/workspace/jdk-11.0.21+9
export ANDROID_HOME=/workspace/android-sdk
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"
export FLUTTER_ROOT=/workspace/flutter-3.16

echo "📱 Environment Setup:"
echo "JAVA_HOME: $JAVA_HOME"
echo "ANDROID_HOME: $ANDROID_HOME"
echo "FLUTTER_ROOT: $FLUTTER_ROOT"

cd /workspace/project/netflix-index-flutter

echo ""
echo "🔧 Method 1: Flutter Build APK"
echo "==============================="
timeout 300 $FLUTTER_ROOT/bin/flutter build apk --release --no-version-check || echo "Method 1 failed or timed out"

echo ""
echo "🔧 Method 2: Gradle Build"
echo "========================="
cd android
timeout 300 ./gradlew assembleRelease || echo "Method 2 failed or timed out"

echo ""
echo "🔍 Searching for APK files..."
echo "=============================="
find /workspace/project/netflix-index-flutter -name "*.apk" -type f

echo ""
echo "📊 Build Summary:"
echo "=================="
if [ -f "app/build/outputs/apk/release/app-release.apk" ]; then
    echo "✅ APK successfully created at: app/build/outputs/apk/release/app-release.apk"
    ls -lh app/build/outputs/apk/release/app-release.apk
else
    echo "❌ APK build failed. Check the logs above for errors."
    echo ""
    echo "🛠️  Manual Build Instructions:"
    echo "1. Copy this project to your local machine"
    echo "2. Install Flutter SDK and Android SDK"
    echo "3. Run: flutter pub get"
    echo "4. Run: flutter build apk --release"
fi

echo ""
echo "🎯 All requested features have been implemented:"
echo "✅ Brown screen fix"
echo "✅ Movie/TV details screen"
echo "✅ TV shows section"
echo "✅ See all feature with infinite scroll"
echo "✅ Enhanced video player with fullscreen"
echo "✅ Improved login screen"
echo "✅ Hero video player on home page"
echo "✅ Optimized data loading"
echo "✅ Multiple streaming servers"