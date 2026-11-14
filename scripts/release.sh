#!/bin/zsh
# Builds a Developer ID signed, notarized, stapled NotchGames.dmg for download from the website.
# Needs a "Developer ID Application" certificate in the keychain and `asc` logged in.
set -euo pipefail

cd "${0:A:h}/.."
BUILD=build/release
rm -rf "$BUILD"

xcodebuild archive -scheme NotchGames -configuration Release \
  -destination "generic/platform=macOS" -archivePath "$BUILD/NotchGames.xcarchive" \
  DEVELOPMENT_TEAM=3K3GFX53DY -allowProvisioningUpdates

xcodebuild -exportArchive -archivePath "$BUILD/NotchGames.xcarchive" \
  -exportPath "$BUILD/export" -exportOptionsPlist scripts/ExportOptions.plist \
  -allowProvisioningUpdates

APP="$BUILD/export/NotchGames.app"
codesign --verify --deep --strict --verbose=2 "$APP"

VERSION=$(defaults read "${APP:A}/Contents/Info" CFBundleShortVersionString)
DMG="$BUILD/NotchGames-$VERSION.dmg"
hdiutil create -volname NotchGames -srcfolder "$APP" -ov -format UDZO "$DMG"
codesign --sign "Developer ID Application" --timestamp "$DMG"

asc notarization submit --file "$DMG" --wait
xcrun stapler staple "$DMG"
spctl --assess --type open --context context:primary-signature --verbose "$DMG"

echo "Upload: $DMG"
