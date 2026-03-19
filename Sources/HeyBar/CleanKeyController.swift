import AppKit
import Combine
import SwiftUI

@MainActor
final class CleanKeyController: ObservableObject {
    enum UnlockReason {
        case completed
        case manual
        case escTap
        case permissionRevoked
        case setupFailure
    }

    private enum DefaultsKey {
        static let durationMinutes = "cleanKey.durationMinutes"
        static let soundEnabled = "cleanKey.soundEnabled"
    }

    @Published private(set) var hasAccessibilityPermission = false
    @Published private(set) var isCleaning = false
    @Published private(set) var escTapProgress: Double = 0
    @Published private(set) var remainingSeconds = 0
    @Published var durationMinutes: Int {
        didSet {
            durationMinutes = max(1, min(durationMinutes, 60))
            defaults.set(durationMinutes, forKey: DefaultsKey.durationMinutes)
        }
    }
    @Published var soundEnabled: Bool {
        didSet {
            defaults.set(soundEnabled, forKey: DefaultsKey.soundEnabled)
        }
    }
    @Published var lastError: String?

    let durationOptions = [1, 3, 5, 10, 15, 20, 30, 45, 60]

    private let permissionManager: CleanKeyPermissionManager
    private let eventBlocker = CleanKeyEventBlocker()
    private let countdownManager = CleanKeyCountdownManager()
    private let defaults: UserDefaults
    private var securityCheckTimer: AnyCancellable?
    private var countdownCancellable: AnyCancellable?
    private var permissionPollTimer: AnyCancellable?
    // Separate state object to break the NSHostingView → View retain cycle.
    private let overlayState = CleanKeyOverlayState()
    private var overlayCancellables = Set<AnyCancellable>()
    private var overlayWindows: [NSWindow] = []
    private var cursorHidden = false

    init(
        permissionManager: CleanKeyPermissionManager = CleanKeyPermissionManager(),
        defaults: UserDefaults = .standard
    ) {
        self.permissionManager = permissionManager
        self.defaults = defaults
        durationMinutes = defaults.object(forKey: DefaultsKey.durationMinutes) as? Int ?? 5
        soundEnabled = defaults.object(forKey: DefaultsKey.soundEnabled) as? Bool ?? true

        refreshPermissionStatus()
        if !hasAccessibilityPermission {
            startPermissionPolling()
        }

        countdownManager.onFinish = { [weak self] in
            Task { @MainActor [weak self] in
                self?.unlock(reason: .completed)
            }
        }

        countdownCancellable = countdownManager.$remainingSeconds
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.remainingSeconds = value
            }

        // Sync values into the overlay state object, which the overlay view observes directly.
        $escTapProgress
            .receive(on: DispatchQueue.main)
            .sink { [overlayState] value in overlayState.escTapProgress = value }
            .store(in: &overlayCancellables)

        $remainingSeconds
            .receive(on: DispatchQueue.main)
            .sink { [overlayState] value in overlayState.remainingSeconds = value }
            .store(in: &overlayCancellables)
    }

    var statusText: String {
        if isCleaning {
            return remainingBadgeText
        }
        return hasAccessibilityPermission ? "Ready" : "Needs Access"
    }

    var remainingBadgeText: String {
        guard isCleaning else { return "OFF" }
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return mins > 0 ? "\(mins)m" : "\(secs)s"
    }

    func refreshPermissionStatus() {
        hasAccessibilityPermission = permissionManager.isAccessibilityTrusted
    }

    func requestAccessibilityPermission() {
        // Wipe any stale TCC entry before prompting. When the binary changes
        // (e.g. after an in-app update), macOS keeps the old code-signature in the
        // TCC database and rejects the new binary even if the toggle appears ON in
        // System Settings. Resetting first guarantees a clean prompt.
        resetTCCEntry()
        permissionManager.promptAccessibilityPermission()
        refreshPermissionStatus()
        if !hasAccessibilityPermission {
            lastError = UserFacingMessages.accessibilityPermissionRequired
        } else {
            lastError = nil
        }
    }

    func openAccessibilitySettings() {
        permissionManager.openAccessibilitySettings()
    }

    private func resetTCCEntry() {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.gravity.heybar"
        let tccutil = Process()
        tccutil.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        tccutil.arguments = ["reset", "Accessibility", bundleID]
        tccutil.standardOutput = FileHandle.nullDevice
        tccutil.standardError = FileHandle.nullDevice
        try? tccutil.run()
        tccutil.waitUntilExit()
    }

    // Poll AXIsProcessTrusted every 0.5 s until permission is granted.
    // This is more reliable than NSApplication.didBecomeActiveNotification
    // for LSUIElement apps where activation events may not fire consistently.
    private func startPermissionPolling() {
        guard permissionPollTimer == nil else { return }
        permissionPollTimer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.refreshPermissionStatus()
                if self.hasAccessibilityPermission {
                    self.lastError = nil
                    self.permissionPollTimer = nil
                }
            }
    }

    @discardableResult
    func startCleaning() -> Bool {
        guard !isCleaning else { return true }
        refreshPermissionStatus()
        guard hasAccessibilityPermission else {
            permissionManager.promptAccessibilityPermission()
            refreshPermissionStatus()
            lastError = UserFacingMessages.accessibilityPermissionRequired
            return false
        }

        escTapProgress = 0
        lastError = nil
        isCleaning = true
        remainingSeconds = durationMinutes * 60
        NSApp.activate(ignoringOtherApps: true)

        if soundEnabled {
            CleanKeySoundManager.shared.playLock()
        }

        let started = eventBlocker.start(
            allowedProcessID: pid_t(ProcessInfo.processInfo.processIdentifier),
            onEscTapProgress: { [weak self] progress in
                Task { @MainActor [weak self] in
                    guard let self, self.isCleaning else { return }
                    self.escTapProgress = progress
                    if self.soundEnabled {
                        CleanKeySoundManager.shared.playTap(progress: progress)
                    }
                }
            },
            onEscTapTriggered: { [weak self] in
                Task { @MainActor [weak self] in
                    self?.unlock(reason: .escTap)
                }
            },
            onTapInterruption: { [weak self] in
                Task { @MainActor [weak self] in
                    self?.lastError = "CleanKey mode was interrupted and has been stopped."
                    self?.unlock(reason: .setupFailure)
                }
            }
        )

        guard started else {
            isCleaning = false
            lastError = "CleanKey mode could not start."
            return false
        }

        presentOverlayWindows()
        hideCursorForCleaning()
        countdownManager.start(duration: durationMinutes * 60)
        armSecurityCheck()
        return true
    }

    func stopCleaning() {
        unlock(reason: .manual)
    }

    func unlock(reason: UnlockReason) {
        guard isCleaning else { return }
        isCleaning = false
        escTapProgress = 0
        securityCheckTimer?.cancel()
        securityCheckTimer = nil
        countdownManager.cancel()
        eventBlocker.stop()

        if soundEnabled {
            CleanKeySoundManager.shared.playUnlock()
        }

        popTransparentCursor()
        removeOverlayWindows()
        refreshPermissionStatus()

        switch reason {
        case .permissionRevoked:
            lastError = UserFacingMessages.accessibilityPermissionRequired
        case .setupFailure:
            break
        case .completed, .manual, .escTap:
            lastError = nil
        }
    }

    private func armSecurityCheck() {
        securityCheckTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                // AXIsProcessTrusted() makes an IPC call to the Accessibility server;
                // evaluate it off the main thread to avoid brief stalls.
                Task.detached { [weak self] in
                    let trusted = AXIsProcessTrusted()
                    await MainActor.run { [weak self] in
                        guard let self, self.isCleaning, !trusted else { return }
                        self.unlock(reason: .permissionRevoked)
                    }
                }
            }
    }

    private func presentOverlayWindows() {
        removeOverlayWindows()

        for screen in NSScreen.screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.isReleasedWhenClosed = false
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            window.backgroundColor = .clear
            window.isOpaque = false
            window.ignoresMouseEvents = false
            window.hasShadow = false
            window.hidesOnDeactivate = false
            window.isMovable = false
            window.contentView = NSHostingView(rootView: CleanKeyOverlayView(
                state: overlayState,
                onStop: { [weak self] in self?.stopCleaning() }
            ))
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            overlayWindows.append(window)
        }
    }

    private func removeOverlayWindows() {
        for window in overlayWindows {
            window.contentView = nil
            window.orderOut(nil)
            window.close()
        }
        overlayWindows.removeAll()
    }

    private func hideCursorForCleaning() {
        pushTransparentCursor()
    }

    private func pushTransparentCursor() {
        guard !cursorHidden else { return }
        cursorHidden = true
        CGDisplayHideCursor(kCGNullDirectDisplay)
    }

    private func popTransparentCursor() {
        guard cursorHidden else { return }
        cursorHidden = false
        // One CGDisplayShowCursor balances the single CGDisplayHideCursor call.
        CGDisplayShowCursor(kCGNullDirectDisplay)
        NSCursor.arrow.set()
        let location = NSEvent.mouseLocation
        if let screen = NSScreen.main ?? NSScreen.screens.first {
            let cgY = screen.frame.height - location.y
            CGWarpMouseCursorPosition(CGPoint(x: location.x + 1, y: cgY))
            CGWarpMouseCursorPosition(CGPoint(x: location.x, y: cgY))
        }
    }
}
