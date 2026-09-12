#!/bin/bash
set -euo pipefail
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
export PATH="$JAVA_HOME/bin:/Users/mac/Library/Android/sdk/platform-tools:$PATH"
export ANDROID_HOME="/Users/mac/Library/Android/sdk"
cd /Users/mac/MemoryGame/android

GRADLE_BIN="/Users/mac/.gradle/wrapper/dists/gradle-8.11.1-bin/bpt9gzteqjrbo1mjrsomdt32c/gradle-8.11.1/bin/gradle"

echo "Building signed release APK (v1.1 / versionCode 5)..."
if [ -x "$GRADLE_BIN" ]; then
  "$GRADLE_BIN" :app:assembleRelease --no-daemon
else
  ./gradlew :app:assembleRelease --no-daemon
fi

APK="app/build/outputs/apk/release/app-release.apk"
echo ""
if [ -f "$APK" ]; then
  ls -lh "$APK"
  echo "SUCCESS: $(pwd)/$APK"
  open -R "$APK"
else
  echo "FAILED: APK not found"
  exit 1
fi
