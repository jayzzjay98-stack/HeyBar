# Known Issues

## ~~Settings Window Z-Order / Positioning Problem~~ ✅ RESOLVED (2026-03-20)

> **Fix**: Destroy and recreate `SettingsWindowController` on every show (instead of reusing a stale `NSWindow`). Clear `onWindowClose` before closing to prevent the helper process from terminating prematurely. Double-center the window — once before `makeKeyAndOrderFront` and once async after — with `setFrame(display: true)` to commit the frame synchronously.
>
> **Files changed**: `AppDelegate.swift` (`showSettingsWindow()`), `SettingsWindowController.swift` (`present()`, `centerWindowOnActiveScreen()`)

---

## Settings Window Z-Order / Positioning Problem (Historical — Archived)

### Description
When the Settings window is opened from the **menu bar** (status bar icon → Quick Controls → Settings button), macOS window behavior is still unreliable. The original z-order bug can be avoided by keeping the app `.regular`, but the current menu-bar-only architecture still has an unresolved window-positioning issue: the Settings window may reopen near the right edge of the screen instead of appearing centered. Opening Settings from the menu bar also feels slightly slower than opening a normal in-process window because a separate helper process is involved.

### Steps to Reproduce
1. Open Google Chrome (or any other app)
2. Click HeyBar's status bar icon (`|`) to open Quick Controls
3. Click "Settings" to open the Settings window — it appears in front (correct)
4. Open a third app (e.g. Notes, Finder, etc.)
5. Close the third app
6. **Expected**: Settings window should appear centered on the active screen and maintain normal macOS ordering
7. **Actual**: in menu-bar mode it can reopen at a stale position near the right edge, and historically it could also fall behind other apps depending on activation policy

### Important Note
- Opening Settings from **Applications folder** or running the app as `.regular` works correctly
- The issue is tied specifically to the **menu bar / helper-process path**
- The helper-process approach improves Dock behavior, but does **not** reliably force the Settings window to reopen centered

### Root Cause Analysis
There are effectively **two different problems** depending on architecture:

1. **Single-process accessory → regular switching**
   HeyBar runs as an **accessory app** (`NSApp.setActivationPolicy(.accessory)`) by default. When Settings is opened in-process, the app must temporarily switch to **regular** mode (`NSApp.setActivationPolicy(.regular)`).

   **The problem**: macOS does not properly track z-order for apps that dynamically switch from `.accessory` to `.regular`. Even if activation APIs visually bring the window forward, macOS's internal app ordering may stay wrong.

2. **Helper-process architecture (current implementation)**
   The current build avoids the Dock/z-order tradeoff by launching a separate `.regular` helper process for Settings while the main app stays menu-bar-only.

   **The new problem**: even with a helper, opening Settings from the menu bar can still reopen the window using stale positioning behavior. Attempts to recenter on show have not been reliable enough in practice. The helper path also adds a small but noticeable launch delay compared with a normal in-process settings window.

### What Has Been Tried (All Failed)

1. **`window.orderFrontRegardless()`** — Brings window to front visually but doesn't fix macOS's internal z-order tracking. Window falls behind again when another app closes.

2. **`NSApp.activate(ignoringOtherApps: true)`** — Same as above. Activates the app momentarily but doesn't fix the underlying ordering.

3. **`NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])`** — More powerful activation API, but still doesn't fix the z-order for accessory→regular policy switches.

4. **`window.level = .floating`** — Keeps the window above ALL other windows at all times. **Works but rejected** because it prevents the user from putting other app windows in front of Settings.

5. **`NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration:)`** — Triggers `applicationShouldHandleReopen` through macOS's standard activation path. Still doesn't fix z-ordering.

6. **`/usr/bin/open` subprocess** — Launches the app through the standard open command. Same result as #5.

7. **`NSWorkspace.didTerminateApplicationNotification` observer** — Re-activates HeyBar when another app terminates. Doesn't fire reliably (many macOS apps don't terminate when their window closes).

8. **`NSWorkspace.didDeactivateApplicationNotification` observer** — Re-activates HeyBar when another app deactivates. **Causes side effects**: steals focus when the user intentionally switches to another app.

9. **Delay-based re-activation (80ms–250ms)** — Adds a delay before activating after another app closes. Causes visible **flicker** where Chrome briefly appears then HeyBar jumps to front.

10. **`window.collectionBehavior = [.managed, .participatesInCycle]`** — Tells macOS to manage the window in Mission Control and app cycling. Does not fix the z-order issue.

11. **`window.hidesOnDeactivate = false`** — Prevents the window from hiding when the app loses active status. **Works for hiding**, but doesn't fix z-ordering.

12. **Reversing call order in `openSettingsAction()`** — Changed from `onClose() → openSettings()` to `openSettings() → onClose()` so the Settings window exists before the Quick Controls panel closes. Prevents a moment with zero windows, but doesn't fix the z-order tracking issue.

13. **Dynamic floating level (float when resigned, normal when active)** — Sets `window.level = .floating` when app resigns active, `.normal` when becomes active. Should theoretically work but did NOT fix the issue in practice.

14. **Separate helper process for Settings** — Main app stays `.accessory`, helper runs `.regular`. This avoids the worst Dock/z-order compromise, but it introduces a new issue: the Settings window can still reopen near the screen edge instead of centering reliably.

15. **Explicit recentering via `window.center()`** — Too weak for the helper path. In practice the window can still reopen at the old position.

16. **Manual `setFrame` to the active screen's `visibleFrame`** — Helped in some runs but did not solve the issue consistently for the real menu-bar launch path.

17. **Distributed notification from main app to helper** — Used so the running helper could reopen/recenter its existing Settings window. Did not reliably fix the stale-position behavior in practice.

18. **Disable window restoration / disable animation / reorder activation calls** — Reduced flicker, but still did not reliably force the Settings window to open centered from the menu bar path.

### Relevant Files

| File | Role |
|------|------|
| `Sources/HeyBar/AppDelegate.swift` | `showSettings()` method — sets `.regular` policy and presents window |
| `Sources/HeyBar/SettingsWindowController.swift` | Creates the NSWindow, manages observers for close/activate |
| `Sources/HeyBar/QuickControlsViewController.swift` | `openSettingsAction()` — triggers settings from Quick Controls panel |
| `Sources/HeyBar/QuickControlsPanelController.swift` | Manages the NSPanel (level: `.statusBar`) for Quick Controls |
| `Sources/HeyBar/StatusBarController.swift` | Creates the status bar item and passes `settingsHandler` closure |

### Historical Code Flow (Single Process Menu Bar → Settings)

```
User clicks status bar icon (|)
  → StatusBarController.handleClick()
  → QuickControlsPanelController.toggle(relativeTo:)
  → Quick Controls panel appears (NSPanel, level: .statusBar)

User clicks "Settings" button in Quick Controls
  → QuickControlsViewController.openSettingsAction()
  → openSettings() closure fires (settingsHandler)
  → AppDelegate.showSettings()
      → NSApp.setActivationPolicy(.regular)     // Switch from accessory to regular
      → settingsWindowController.present()       // Show the window
      → NSRunningApplication.current.activate()  // Activate the app
  → onClose?() fires
  → QuickControlsPanelController.close()
  → Quick Controls panel fades out (0.12s animation)
```

### Current Code Flow (Menu Bar → Settings Helper)

```
User clicks status bar icon (|)
  → StatusBarController.handleClick()
  → QuickControlsPanelController.toggle(relativeTo:)
  → Quick Controls panel appears

User clicks "Settings"
  → QuickControlsViewController.openSettingsAction()
  → AppDelegate.showSettings()
      → if helper already exists:
           send distributed notification to helper
        else:
           launch same executable with --settings-helper
      → helper process runs as .regular
      → helper presents SettingsWindowController
```

### Key Code Flow (Applications Folder / Regular App — Works Correctly)

```
User double-clicks HeyBar.app in Applications
  → macOS activates HeyBar through standard activation path
  → applicationShouldHandleReopen() fires
  → showSettings()
  → Window appears with proper z-order tracking ✓
```

### Current Status (2026-03-20)

1. **Confirmed working**: keeping HeyBar `.regular` all the time fixes the original z-order bug.
2. **Rejected tradeoff**: always showing a Dock icon is not acceptable for the intended menu-bar UX.
3. **Current implementation**: helper-process approach is in place.
4. **Still unresolved**: the helper path does not reliably center the Settings window when opened from the menu bar, and it feels slightly slower than an in-process window.

### Potential Solutions Not Yet Tried

1. **Create a true separate helper app bundle** instead of relaunching the same executable with a flag. Trade-off: more packaging and shared-state complexity, but macOS may treat the window lifecycle more predictably.

2. **Destroy and recreate the Settings window every time** the helper is asked to show it, instead of reusing the same window/controller instance. Trade-off: slightly more churn, but may avoid stale frame behavior.

3. **Use a dedicated IPC mechanism** (XPC or Apple Events) instead of distributed notifications so the helper can receive a stronger "show fresh settings now" command. Trade-off: more complexity.

4. **Use `CGSOrderWindow` / private WindowServer API** — directly manipulate macOS's internal ordering/positioning. Trade-off: private API, fragile, not App Store compatible.

5. **Present Settings in an `NSPanel` subclass** instead of `NSWindow`. Trade-off: different behavior/appearance and still not guaranteed.

6. **Use Accessibility API** (`AXUIElement`) to reposition/raise the window externally. Trade-off: requires accessibility permission and adds user-facing setup friction.
