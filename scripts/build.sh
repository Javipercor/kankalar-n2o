#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
APP="$PWD/build/N2O.app"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources" "$PWD/build/AppIcon.iconset"
xcrun swift scripts/make-icon.swift "$PWD/build/AppIcon.iconset"
iconutil -c icns "$PWD/build/AppIcon.iconset" -o "$APP/Contents/Resources/AppIcon.icns"
xcrun swiftc -O -parse-as-library -target "$(uname -m)-apple-macosx14.0" Sources/N2O.swift -o "$APP/Contents/MacOS/N2O"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>N2O</string>
<key>CFBundleIdentifier</key><string>local.n2o.gpumemory</string>
<key>CFBundleName</key><string>N2O</string>
<key>CFBundleDisplayName</key><string>N₂O</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>CFBundleVersion</key><string>4</string>
<key>LSUIElement</key><true/>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
printf 'App creada: %s\n' "$APP"
