# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [v1.1.1] - 2026-03-23

### Fixed
- quick-controls: panel order and visibility now stay in sync with the Customize page, including updates coming from the Settings helper process

## [v1.1.0] - 2026-03-23

### Changed
- settings: move the Settings experience onto a helper-process path so HeyBar can stay menu-bar-first without forcing a permanent Dock icon
- settings: reduce opening flicker and simplify helper activation when opening Settings from Quick Controls

### Fixed
- dock: remove the main-app Dock icon from the normal menu-bar flow

### Known Issues
- settings: opening Settings from the menu bar can still reopen the window at a stale position instead of centered; see `KNOWN_ISSUES.md`

## [v0.2.0] - 2026-03-19

### Added
- quick-controls: ON-state tiles now glow with a colored shadow matching the theme's enabled fill
- quick-controls: tile icons switch to filled variants when a feature is active (bolt.fill for Keep Awake, moon.stars.fill for Night Shift, arrow variants for Hide Dock and Hide Bar)
- quick-controls: Keep Awake tile badge shows a live countdown ("14m", "59s") when duration mode is active
- quick-controls: shortcut keys appear as a caption on each tile when a shortcut is assigned
- quick-controls: toast notification confirms every toggle with the feature name and new state
- quick-controls: panel starts a 1-second refresh timer while visible, stops when closed
- settings: Keep Awake mode picker replaced with a segmented control (Manual / Duration / Schedule), reducing visible controls to only what is relevant
- settings: Keep Awake card header shows time remaining ("14m left") during an active duration countdown
- status-bar: menu bar icon switches to a bolt symbol while Keep Awake is active
- onboarding: first-launch popover explains left-click and right-click behavior on the menu bar icon
- about: full About page listing version, what's new, all features, and compatibility notes

### Changed
- architecture: split settings, quick controls, theme catalog, shortcuts, status bar, and system-preference code into smaller focused modules
- diagnostics: add opt-in debug logging and a reusable smoke-launch script
- packaging: bump version to 0.2.0, build 3
- quick-controls: extract tile state mapping into a testable model to reduce AppKit-coupled panel logic
- quick-controls: calmer header, open/close motion, hover feedback, and more consistent ON/OFF/N/A visual states
- settings: shared interactive state tokens, calmer typography, and help-state cards for setup and unsupported features

### Fixed
- key-light: normalize negative off-state brightness readings from the private bridge to `0.0`
- system-controls: Hidden Files, Hide Dock, Hide Bar, Night Shift, and Key Light controllers use injected adapters for testability
- ui: readability improved across lighter themes by separating disabled and inactive states from normal OFF states

### Testing
- tests: expand behavioral coverage from 9 to 26 automated tests across shortcuts, keep-awake scheduling, quick controls, status bar behavior, system preferences, and display features

## [v0.1.1] - 2026-03-19

### Changed
- ui: replace repeated layout numbers with named constants

### Fixed
- keep-awake: correct overnight schedule window calculation
- shortcuts: clear unavailable saved shortcuts and support delete key recording
- panel: stop leaking quick controls global event monitor
- settings: refresh launch at login state and surface registration failures

<!-- recommended-semver-bump: patch -->
