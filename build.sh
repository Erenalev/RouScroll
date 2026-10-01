#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"
APP="$PWD/RouScroll.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
xcrun swiftc Sources/main.swift -o "$APP/Contents/MacOS/RouScroll" -module-cache-path "${TMPDIR:-/tmp}/rouscroll-module-cache" -target arm64-apple-macosx13.0 -O -framework AppKit -framework SwiftUI -framework CoreGraphics -framework ServiceManagement
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>RouScroll</string>
<key>CFBundleIdentifier</key><string>com.rouscroll.mac</string>
<key>CFBundleName</key><string>RouScroll</string>
<key>CFBundleDisplayName</key><string>RouScroll</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.5.0</string>
<key>CFBundleVersion</key><string>5</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier ${ROUSCROLL_BUNDLE_ID:-com.rouscroll.mac}" "$APP/Contents/Info.plist"
cp Assets/Logo.png "$APP/Contents/Resources/Logo.png"
cp Assets/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
if [[ -n "${ROUSCROLL_SIGN_IDENTITY:-}" ]]; then
    codesign --force --sign "$ROUSCROLL_SIGN_IDENTITY" --timestamp=none "$APP"
else
    codesign --force --sign - "$APP"
fi
codesign --verify --strict "$APP"
"$APP/Contents/MacOS/RouScroll" --self-test
echo "Built: $APP"
