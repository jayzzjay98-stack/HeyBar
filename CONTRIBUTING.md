# Contributing to HeyBar

Thank you for taking the time to contribute! Here's everything you need to get started.

## Getting Started

1. Fork the repository and clone your fork
2. Make sure you're on macOS 13 or later with Xcode 15+ installed
3. Build the project: `swift build`
4. Run tests: `swift test`

## Reporting Bugs

Before opening an issue, please check that no existing issue already covers your problem.

When filing a bug report, include:
- macOS version
- HeyBar version (visible in Settings → About)
- Steps to reproduce
- What you expected vs. what happened
- Any relevant console output (`HEYBAR_DEBUG_LOGGING=1 open /Applications/HeyBar.app`)

## Suggesting Features

Open a GitHub Issue with the label `enhancement`. Describe the use case and why it would benefit most users.

## Pull Requests

### Branch naming

| Type | Pattern | Example |
|------|---------|---------|
| Feature | `feat/<short-name>` | `feat/escape-to-close` |
| Bug fix | `fix/<short-name>` | `fix/badge-color-light-themes` |
| Refactor | `refactor/<short-name>` | `refactor/timer-runloop-mode` |
| Docs | `docs/<short-name>` | `docs/update-readme` |

### Before opening a PR

- [ ] `swift build` succeeds with no warnings
- [ ] `swift test` passes
- [ ] New behavior is covered by a test where practical
- [ ] UI changes are tested across at least two themes (one dark, one light)
- [ ] No hardcoded colors — use `AppTheme` properties instead

### PR description

Use this template:

```
## What
Brief description of the change.

## Why
Motivation or issue link.

## Testing
How you verified it works.
```

## Code Style

- Follow the existing Swift conventions in the codebase
- `@MainActor` on all UI classes
- Prefer `weak self` in closures that could create retain cycles
- Use named constants in `QuickControlsLayout` / `SettingsLayout` — no magic numbers
- Colors always come from `AppTheme` — never hardcode hex values in UI code

## Architecture Notes

| Layer | Location | Responsibility |
|-------|----------|----------------|
| App entry | `AppDelegate.swift` | Lifecycle, status bar setup |
| State | `AppModel.swift` | Single source of truth, published properties |
| Controllers | `*Controller.swift` | Business logic per feature |
| Panel UI | `QuickControls*.swift` | AppKit panel and tile components |
| Settings UI | `Settings*.swift` | SwiftUI settings window |
| Theming | `AppTheme.swift`, `ThemeCatalog.swift` | Color derivation and theme registry |

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
