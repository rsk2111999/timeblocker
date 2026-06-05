#!/bin/bash
set -e

APP="TimeBlocker"
BUNDLE="${APP}.app"
DEST="/Applications/${BUNDLE}"

if [ ! -d "${BUNDLE}" ]; then
    echo "❌ ${BUNDLE} not found. Run ./build.sh first."
    exit 1
fi

echo "🔧 Installing ${APP}..."

# Quit running instance, if any
if pgrep -x "${APP}" > /dev/null 2>&1; then
    osascript -e "tell application \"${APP}\" to quit" 2>/dev/null || killall "${APP}" 2>/dev/null || true
    sleep 1
fi

# Remove old installation
if [ -d "${DEST}" ]; then
    sudo rm -rf "${DEST}"
fi

sudo cp -R "${BUNDLE}" "${DEST}"
echo "✅ Installed to ${DEST}"

# Launch — first launch registers itself as a login item automatically
open "${DEST}"
echo "✅ Launched ${APP}"
echo ""
echo "Time Blocker is now running in your menu bar (⏱)."
echo "It auto-starts on login — check System Settings → General → Login Items."
