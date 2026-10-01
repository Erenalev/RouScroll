# Contributing to RouScroll

Thanks for helping improve RouScroll.

## Before opening an issue

- Check whether the issue has already been reported.
- Include your macOS version, Mac architecture and input device model.
- Mention third-party mouse drivers and other scroll utilities.
- List the master, device and axis switch settings.
- Describe the expected direction and the actual direction.

## Development

Build and run the deterministic checks with `zsh build.sh` on an Apple Silicon Mac running macOS 13 or later. A physical-device check is needed for changes to scroll classification or event handling.

Keep UI changes native and compact. Do not display Active unless the event tap is enabled. Permission prompts should appear on explicit start attempts, not repeatedly during background retries.

## Translations

Add or update strings in `AppLanguage.translations` in `Sources/main.swift`. Keep the same keys across all languages. Check both the main panel and Settings, including longer German/French labels and permission dialogs.

## Pull requests

Explain the user-visible problem and behavior after the change. Include what you tested and any hardware you used. Keep unrelated changes separate. Do not commit compiled applications, private certificates, keys, personal paths or temporary diagnostics.

Contributions are made under the repository's MIT license.
