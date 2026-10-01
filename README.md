<p align="center">
  <img src="Assets/Logo.png" alt="RouScroll logo" width="160">
</p>

# RouScroll

**Your scroll direction. Your choice.**

[Features](#features) · [Installation](#installation) · [Languages](#languages) · [Build and test](#build-and-test) · [Troubleshooting](#troubleshooting)

A lightweight, native macOS menu bar app for controlling your scroll direction.

RouScroll lets you reverse mouse-wheel scrolling while keeping trackpad scrolling unchanged, or configure both independently. Vertical and horizontal reversal have separate switches. Everything lives in a compact translucent menu bar panel, with no Dock icon or main window.

## Features

- Separate reversal switches for mouse-wheel and trackpad-style scrolling.
- Independent vertical and horizontal direction controls.
- A master switch that shows the actual scroll-filter state.
- A native translucent menu bar interface using AppKit and SwiftUI.
- English by default, with Turkish, German and French available in Settings.
- Immediate language changes, saved between launches.
- Optional launch at login, using macOS ServiceManagement.
- Local preferences; no account, analytics, network requests or scroll-event logging.

## Requirements

- macOS 13 Ventura or later.
- Apple Silicon Mac (M1 or newer) for the current build script.
- Accessibility permission on each Mac where you use the app.
- Xcode Command Line Tools or Xcode to build from source.

Intel Macs are not supported by the current prebuilt application. A universal build would require compiling and validating an Intel slice as well.

## Installation

1. Build the app from source using the commands below. A prebuilt ZIP is also available when attached to a GitHub release.
2. Move `RouScroll.app` into your Applications folder before enabling launch at login.
3. Open RouScroll. If macOS blocks the locally signed build, review the notice in **System Settings → Privacy & Security**. Only open an app whose source and origin you trust.
4. When prompted, open **System Settings → Privacy & Security → Accessibility** and add/enable the exact copy of `RouScroll.app` you are running.
5. RouScroll checks again automatically. The master switch becomes enabled only when the scroll filter is actually running.

The current local build is ad-hoc signed and is not Developer ID signed or notarized. Accessibility permissions do not transfer when you share the app with another Mac.

## Usage

Click the RouScroll logo in the menu bar to open the panel.

| Control | Behavior |
| --- | --- |
| Master switch | Starts or stops the scroll filter. Shows Active only when the filter is running. |
| Mouse wheel | Reverses events classified as mouse-wheel scrolling. |
| Trackpad | Reverses events classified as touch/gesture scrolling. |
| Vertical scrolling | Allows reversal on the vertical axis. |
| Horizontal scrolling | Allows reversal on the horizontal axis. |
| Settings → Language | Select English, Türkçe, Deutsch or Français. |
| Settings → Launch at login | Registers or removes a macOS login item. |
| Quit | Exits RouScroll and removes its scroll filter. |

Each device switch works together with the axis switches. For example, **Mouse wheel on**, **Trackpad off**, **Vertical on**, and **Horizontal off** reverses only the vertical scrolling of mouse-wheel events.

Directions are reversed relative to your current macOS scrolling settings. RouScroll does not change scroll speed, acceleration or the system's Natural Scrolling preference. Disable other scroll-reversal utilities while testing, because two filters can cancel each other out.

If permission is missing, each explicit start attempt shows a permission dialog. Already authorized starts do not show that dialog. Background retries do not repeatedly prompt.

## Languages

The first launch defaults to **English**, regardless of the system language. Choose another language in **Settings → Language**; the interface updates immediately and remembers the selection. Language labels are shown in their native spelling so you can find your way back.

Translations are defined in `AppLanguage.translations` in `Sources/main.swift`. New translations should cover every key, including permission dialogs and login-item messages.

## Build and test

```sh
git clone https://github.com/Erenalev/RouScroll.git
cd RouScroll
zsh build.sh
```

This builds `RouScroll.app`, signs it locally, verifies its signature, and runs the deterministic checks. To run checks independently:

```sh
./RouScroll.app/Contents/MacOS/RouScroll --self-test
```

The checks cover 192 scroll-field combinations, smooth-mouse versus touch-momentum classification, and the completeness of every language table. They do not simulate physical mouse/trackpad hardware or grant Accessibility permission.

To sign with a code-signing identity you already have:

```sh
ROUSCROLL_SIGN_IDENTITY='Your code signing identity' zsh build.sh
```

This signing option does not notarize the app or implement the full Developer ID distribution workflow.

To create a ZIP:

```sh
ditto -c -k --sequesterRsrc --keepParent RouScroll.app RouScroll.zip
```

## Troubleshooting

**Permission is enabled, but scrolling is inactive:** macOS may still have a permission entry for an older build or a different copy of the app. Remove that RouScroll entry, add the exact current application again, and allow access. Rebuilding an ad-hoc-signed executable changes its code identity and may require this step again.

**A mouse is treated as a trackpad:** classification uses scroll gesture and momentum phases, not a physical device identifier. Magic Mouse and third-party driver behavior may vary. Per-device configuration is not currently available.

**Launch at login needs approval:** check **System Settings → General → Login Items**. Keep the app in a stable location.

**The panel looks opaque:** macOS accessibility settings such as Reduce Transparency can change the appearance of native materials.

## How it works

A Core Graphics session event tap receives scroll-wheel events. The policy identifies touch-style events from their gesture/momentum phases, then reverses the enabled axes by modifying the line, point and fixed-point delta fields. Fixed-point values are written last because Core Graphics updates related fields together. The run loop keeps the filter active and attempts to recover after sleep or an event-tap interruption.

Only scroll events are requested by the filter. The app does not listen for keystrokes, save event contents, connect to the internet, or modify macOS's global scrolling preferences.

## Contributing

Bug reports, translation improvements and hardware compatibility reports are welcome. Include your macOS version, Mac architecture, mouse/trackpad model, driver software, and which switches are enabled. Do not include passwords or other private information.

For code changes, run `zsh build.sh` and manually check the affected behavior. Keep the menu bar interface compact and retain the permission-gated master switch.

## License

MIT — see [LICENSE](LICENSE).
