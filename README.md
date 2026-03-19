# HeyBar

**Eight macOS system toggles — one click away.**

HeyBar sits in your menu bar and gives you instant access to the controls power users reach for every day: Keep Awake, Hidden Files, File Extensions, Night Shift, Key Light, Hide Dock, Hide Bar, and CleanKey.

![Build](https://github.com/gravity/heybar/actions/workflows/build.yml/badge.svg)
![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift 6](https://img.shields.io/badge/Swift-6-orange)
![License: MIT](https://img.shields.io/badge/License-MIT-green)

---

## Features

| Feature | What it does |
|---------|-------------|
| **Keep Awake** | Prevents display sleep — manual, timed, or scheduled |
| **Hidden Files** | Shows or hides dot-files in Finder instantly |
| **File Extensions** | Reveals full filenames across Finder |
| **Key Light** | Adjusts keyboard backlight brightness |
| **Night Shift** | Toggles warm display color temperature |
| **Hide Dock** | Turns Dock auto-hide on or off |
| **Hide Bar** | Turns menu bar auto-hide on or off |
| **CleanKey** | Locks keyboard and mouse while you clean your screen, with a countdown timer |

### More

- **Themes** — 20 built-in color themes, light and dark
- **Keyboard shortcuts** — assign a global shortcut to any toggle
- **Live countdown** — Keep Awake badge counts down remaining time
- **Toast feedback** — every action confirms with a small notification
- **Onboarding** — guided first-launch setup for permissions

---

## Requirements

- macOS 13 Ventura or later
- Apple Silicon or Intel Mac

---

## Installation

### Download

Download the latest release from the [Releases](../../releases) page and drag `HeyBar.app` to your `/Applications` folder.

### Build from source

```bash
git clone https://github.com/gravity/heybar.git
cd heybar
bash scripts/install_app.sh --install
```

This builds a release binary, assembles the app bundle, signs it ad-hoc, and installs it to `/Applications/HeyBar.app`.

---

## Usage

- **Left-click** the menu bar icon to open the Quick Controls panel
- **Right-click** the menu bar icon to toggle wide spacer mode
- Click any tile to toggle that feature
- Open **Settings** from inside the panel to manage shortcuts, themes, and preferences

---

## Permissions

HeyBar requests permissions only when the relevant feature is used.

| Permission | Required for |
|-----------|-------------|
| **Accessibility** | CleanKey — blocks keyboard and mouse input |
| **Automation** | Hide Dock and Hide Bar — controls System Events |

Neither permission is required to use the other six features.

---

## Compatibility Notes

- **Night Shift** and **Key Light** use private macOS frameworks. They may change behavior after a system update.
- **Hide Dock** and **Hide Bar** require Automation permission in System Settings → Privacy & Security.

---

## Debug Logging

```bash
HEYBAR_DEBUG_LOGGING=1 open /Applications/HeyBar.app
```

Emits diagnostic output to the macOS unified log. Useful for troubleshooting shortcuts, automation, and system-preference commands.

---

## Development

```bash
# Build debug
swift build

# Run tests
swift test

# Build and install release
bash scripts/install_app.sh --install

# Smoke test the installed app
bash scripts/smoke_app_launch.sh
```

### Project structure

```
Sources/
  HideStatusbar/     Main app target — AppKit + SwiftUI
  NightShiftBridge/  Thin ObjC wrapper for the private Night Shift framework
Tests/
  HeyBarTests/       Unit and integration tests
AppBundle/           Info.plist, icon, and PrivacyInfo.xcprivacy
scripts/             Build, install, and asset-capture helpers
docs/                Design system, release notes, and review docs
```

---

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

---

## License

HeyBar is available under the [MIT License](LICENSE).
