#!/bin/bash
# Usage: ./release.sh 1.0.2 "Fixed X, improved Y"
set -e

VERSION=$1
NOTES=$2

if [ -z "$VERSION" ] || [ -z "$NOTES" ]; then
    echo "Usage: ./release.sh <version> \"release notes\""
    echo "Example: ./release.sh 1.0.2 \"Fixed Settings crash, added Safari support\""
    exit 1
fi

APP="MonkMode"
ZIPNAME="$APP-macOS.zip"
CHECKER="Sources/MonkMode/UpdateChecker.swift"

echo "🔖 Bumping version to $VERSION..."
sed -i '' "s/static let currentVersion = \".*\"/static let currentVersion = \"$VERSION\"/" "$CHECKER"
sed -i '' "s/<string>$APP<\/string>/<string>$APP<\/string>/" "Sources/MonkMode/Resources/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "Sources/MonkMode/Resources/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "Sources/MonkMode/Resources/Info.plist"

echo "📦 Building..."
./build.sh

echo "🗜 Zipping..."
cp "$APP.app" /tmp/ -r
ditto -c -k --keepParent "$APP.app" "$ZIPNAME"

echo "💾 Committing..."
git add .
git commit -m "Release v$VERSION"
git tag "v$VERSION"
git push && git push --tags

echo "🚀 Publishing GitHub release..."
gh release create "v$VERSION" "$ZIPNAME" \
    --title "Monk Mode v$VERSION" \
    --notes "## What's new
$NOTES

## Install
1. Download **$ZIPNAME** and unzip
2. Drag \`MonkMode.app\` to \`/Applications\` (replacing the old one)
3. **Right-click → Open** if prompted

**Requires macOS 13 or newer.**"

echo ""
echo "✅ Released v$VERSION"
echo "   Download: https://github.com/ritwik211/monkmode/releases/download/v$VERSION/$ZIPNAME"
echo ""
echo "Existing users will see an update prompt next time they launch the app."
