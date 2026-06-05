# Monk Mode

A macOS menu bar app that blocks distracting apps on a schedule — with a **password-locked focus mode** you can't wriggle out of.

---

## Install

1. Download [**MonkMode-macOS.zip**](https://github.com/ritwik211/monkmode/releases/latest)
2. Unzip and drag `MonkMode.app` to `/Applications`
3. **Right-click → Open** (required once — macOS security prompt)
4. Find the **⏱** icon in your menu bar

> Auto-login: System Settings → General → Login Items → add `MonkMode`

---

## How it works

### Scheduled blocking
Set time windows per app (e.g. block WhatsApp 9am–6pm). The app is killed the instant it opens, and checked every 5 seconds as a fallback.

### 🎯 Focus mode
Manually trigger blocking for 30, 45, 60, 90 min, or 2 hours — regardless of your schedule.

**Once focus mode starts, you cannot pause or disable it without the password.** The pause option disappears entirely. The only exit is typing the correct password.

---

## Setup

Click **⏱ → Settings…** to:
- Add any installed app to the block list
- Set one or more time windows per app (supports overnight windows)
- Remove apps you no longer want to block

---

## Requirements

- macOS 13 (Ventura) or newer
- No admin rights needed to run

---

## Build from source

```bash
git clone https://github.com/ritwik211/monkmode
cd monkmode
./build.sh          # produces MonkMode.app
./install.sh        # copies to /Applications and launches
```

Requires Xcode Command Line Tools: `xcode-select --install`
