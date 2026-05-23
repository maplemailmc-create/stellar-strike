#!/bin/bash
set -euo pipefail

echo "🔨 Building Stellar Strike..."

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA="$PROJECT_DIR/DerivedData"
APP_NAME="ShooterGame"
SCHEME="$APP_NAME"

cd "$PROJECT_DIR"

# Build for iOS device (arm64)
xcodebuild \
  -scheme "$SCHEME" \
  -sdk iphoneos \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA" \
  -destination 'generic/platform=iOS' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  ONLY_ACTIVE_ARCH=NO \
  build 2>&1 | tail -20

# Find the .app
APP_PATH=$(find "$DERIVED_DATA/Build/Products/Release-iphoneos" -maxdepth 1 -name "*.app" | head -1)

if [ -z "$APP_PATH" ]; then
  echo "❌ .app not found!"
  find "$DERIVED_DATA" -name "*.app" 2>/dev/null || echo "No .app anywhere"
  exit 1
fi

echo "✅ Built: $APP_PATH"

# Package into .ipa
echo "📦 Packaging IPA..."
cd "$PROJECT_DIR"
mkdir -p Payload
cp -R "$APP_PATH" Payload/
zip -r "StellarStrike.ipa" Payload/ > /dev/null
rm -rf Payload

echo "✅ IPA created: $PROJECT_DIR/StellarStrike.ipa"
ls -lh "$PROJECT_DIR/StellarStrike.ipa"
