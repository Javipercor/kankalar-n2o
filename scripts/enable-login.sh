#!/bin/bash
set -euo pipefail
APP="/Applications/N2O.app"
LABEL="local.n2o.gpumemory"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
DOMAIN="gui/$(id -u)"
if [ ! -x "$APP/Contents/MacOS/N2O" ]; then
  printf 'Install N2O.app in /Applications first.\n' >&2
  exit 1
fi
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$PLIST" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>local.n2o.gpumemory</string>
  <key>ProgramArguments</key><array>
    <string>/usr/bin/open</string>
    <string>-a</string><string>/Applications/N2O.app</string>
  </array>
  <key>RunAtLoad</key><true/>
</dict></plist>
PLIST
plutil -lint "$PLIST"
if launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1; then
  launchctl bootout "$DOMAIN/$LABEL"
fi
launchctl enable "$DOMAIN/$LABEL"
launchctl bootstrap "$DOMAIN" "$PLIST"
printf 'N2O will open when you log in. Memory limits are not applied automatically.\n'
