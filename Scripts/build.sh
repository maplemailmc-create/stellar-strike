#!/bin/bash
set -euo pipefail

echo "🔨 Building Stellar Strike for iOS..."

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="ShooterGame"
BUNDLE_ID="store.maplemods.stellarstrike"

cd "$PROJECT_DIR"

# Get iOS SDK path
SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
echo "SDK: $SDK_PATH"

# Compile Swift sources directly
echo "📝 Compiling Swift sources..."
swiftc \
  -sdk "$SDK_PATH" \
  -target arm64-apple-ios17.0 \
  -O \
  -framework SwiftUI \
  -framework SpriteKit \
  -framework UIKit \
  -framework Foundation \
  -Xlinker -rpath -Xlinker /usr/lib/swift \
  -Xlinker -rpath -Xlinker @executable_path/Frameworks \
  -o "$APP_NAME" \
  Sources/ShooterGame/*.swift

echo "✅ Binary compiled: $(file $APP_NAME)"

# Create .app bundle structure
echo "📦 Creating .app bundle..."
rm -rf "$APP_NAME.app"
mkdir -p "$APP_NAME.app"

# Copy binary
cp "$APP_NAME" "$APP_NAME.app/$APP_NAME"
chmod +x "$APP_NAME.app/$APP_NAME"

# Copy Info.plist
cp "$PROJECT_DIR/Info.plist" "$APP_NAME.app/Info.plist"

# Create PkgInfo
echo "APPL????" > "$APP_NAME.app/PkgInfo"

# Create launch screen storyboard (minimal)
mkdir -p "$APP_NAME.app/Base.lproj"
cat > "$APP_NAME.app/Base.lproj/LaunchScreen.storyboard" << 'STORYBOARD'
<?xml version="1.0" encoding="UTF-8"?>
<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="21701" targetRuntime="AppleSDK" propertyAccessControl="none" useAutolayout="YES" launchScreen="YES" useTraitCollections="YES" useSafeAreas="YES" colorMatched="YES" initialViewController="01J-lp-oVM">
    <scenes>
        <scene sceneID="EHf-IW-A2E">
            <objects>
                <viewController id="01J-lp-oVM" sceneMemberID="viewController">
                    <view key="view" contentMode="scaleToFill" id="Ze5-6b-2t3">
                        <rect key="frame" x="0.0" y="0.0" width="414" height="896"/>
                        <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                        <color key="backgroundColor" red="0.05" green="0.02" blue="0.1" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
                    </view>
                </viewController>
                <placeholder placeholderIdentifier="IBFirstResponder" id="iYj-Kq-Ea1" userLabel="First Responder" sceneMemberID="firstResponder"/>
            </objects>
            <point key="canvasLocation" x="53" y="375"/>
        </scene>
    </scenes>
</document>
STORYBOARD

# Swift runtime libraries
mkdir -p "$APP_NAME.app/Frameworks"
SWIFT_LIB_DIR=$(xcrun --sdk iphoneos --show-sdk-platform-path)/Developer/Library/Frameworks
# Copy only essential Swift frameworks
for framework in SwiftUICore _SwiftUISwiftUI; do
  if [ -d "$SWIFT_LIB_DIR/$framework.framework" ]; then
    cp -R "$SWIFT_LIB_DIR/$framework.framework" "$APP_NAME.app/Frameworks/"
  fi
done

echo "📱 App bundle created: $APP_NAME.app"
ls -la "$APP_NAME.app/"

# Package into IPA
echo "📦 Creating IPA..."
rm -rf Payload "$APP_NAME.ipa"
mkdir Payload
cp -R "$APP_NAME.app" Payload/
zip -r "$APP_NAME.ipa" Payload/ > /dev/null
rm -rf Payload

echo ""
echo "✅ IPA built: $PROJECT_DIR/$APP_NAME.ipa"
ls -lh "$PROJECT_DIR/$APP_NAME.ipa"
