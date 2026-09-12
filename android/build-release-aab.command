#!/bin/bash
set -euo pipefail
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
export PATH="$JAVA_HOME/bin:/Users/mac/Library/Android/sdk/platform-tools:$PATH"
export ANDROID_HOME="/Users/mac/Library/Android/sdk"
cd /Users/mac/MemoryGame/android

GRADLE_BIN="/Users/mac/.gradle/wrapper/dists/gradle-8.11.1-bin/bpt9gzteqjrbo1mjrsomdt32c/gradle-8.11.1/bin/gradle"

echo "Building signed release AAB (v1.2 / versionCode 6)..."
echo "Ads: LIVE units (release = BuildConfig.DEBUG false)"
echo "targetSdk: 36 | billing-ktx: 8.3.0"
echo ""

if [ -x "$GRADLE_BIN" ]; then
  "$GRADLE_BIN" :app:bundleRelease --no-daemon
else
  ./gradlew :app:bundleRelease --no-daemon
fi

AAB="app/build/outputs/bundle/release/app-release.aab"
echo ""
if [ -f "$AAB" ]; then
  ls -lh "$AAB"
  echo "SUCCESS: $(pwd)/$AAB"
  open -R "$AAB"
else
  echo "FAILED: AAB not found"
  exit 1
fi

echo ""
read -r -p "Press Enter to close..."
