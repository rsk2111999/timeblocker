#!/bin/bash
set -e

APP="TimeBlocker"
BUNDLE="${APP}.app"

echo "⏱  Building ${APP}..."
swift build -c release

BINARY=".build/release/${APP}"
if [ ! -f "${BINARY}" ]; then
    echo "❌ Build failed: binary not found at ${BINARY}"
    exit 1
fi

echo "📦 Creating ${BUNDLE}..."
rm -rf "${BUNDLE}"
mkdir -p "${BUNDLE}/Contents/MacOS"
mkdir -p "${BUNDLE}/Contents/Resources"

cp "${BINARY}" "${BUNDLE}/Contents/MacOS/${APP}"
cp "Sources/TimeBlocker/Resources/Info.plist" "${BUNDLE}/Contents/Info.plist"
chmod +x "${BUNDLE}/Contents/MacOS/${APP}"

echo ""
echo "✅ Built ${BUNDLE}"
echo "   → Run ./install.sh to install to /Applications"
echo "   → Or drag ${BUNDLE} to /Applications manually"
