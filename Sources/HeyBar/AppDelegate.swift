import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private enum SettingsHelperState {
        static let environmentKey = "HEYBAR_SETTINGS_HELPER"
        static let pidDefaultsKey = "heybar.settingsHelperPID"
        static let showNotificationName = Notification.Name("com.gravity.heybar.settingsHelper.show")
        /// Passed as a launch argument so the helper starts without showing a window.
        static let standbyArgument = "--settings-standby"
    }

    private let model = AppModel()
    private var statusBarController: StatusBarController?
    private var settingsWindowController: SettingsWindowController?
    private var onboardingWindowController: OnboardingWindowController?
    private var settingsHelperObserver: NSObjectProtocol?
    private var mainAppTerminationObserver: NSObjectProtocol?
    private let isSettingsHelper =
        ProcessInfo.processInfo.environment[SettingsHelperState.environmentKey] == "1"
        || ProcessInfo.processInfo.arguments.contains("--settings-helper")

    func applicationDidFinishLaunching(_ notification: Notification) {
        model.onQuit = { NSApp.terminate(nil) }

        let environment = ProcessInfo.processInfo.environment
        if isSettingsHelper {
            let isStandby = ProcessInfo.processInfo.arguments.contains(SettingsHelperState.standbyArgument)
            UserDefaults.standard.set(ProcessInfo.processInfo.processIdentifier, forKey: SettingsHelperState.pidDefaultsKey)

            // Listen for the main app to ask us to show the settings window.
            settingsHelperObserver = DistributedNotificationCenter.default().addObserver(
                forName: SettingsHelperState.showNotificationName,
                object: Bundle.main.bundleIdentifier,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.showSettingsWindow()
                }
            }

            // Terminate when the main app process exits (covers crashes too).
            let mainPID = NSWorkspace.shared.runningApplications
                .first(where: {
                    $0.bundleIdentifier == Bundle.main.bundleIdentifier &&
                    $0.processIdentifier != ProcessInfo.processInfo.processIdentifier
                })?.processIdentifier
            if let mainPID {
                mainAppTerminationObserver = NSWorkspace.shared.notificationCenter.addObserver(
                    forName: NSWorkspace.didTerminateApplicationNotification,
                    object: nil,
                    queue: .main
                ) { notification in
                    guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                          app.processIdentifier == mainPID else { return }
                    Task { @MainActor in NSApp.terminate(nil) }
                }
            }

            if !isStandby {
                showSettingsWindow()
            }
            return
        }

        NSApp.setActivationPolicy(.accessory)

        _ = model.shortcuts

        statusBarController = StatusBarController(model: model, settingsHandler: { [weak self] in
            self?.showSettings()
        })
        statusBarController?.setVisible(true)

        // Pre-warm the settings helper so the first open is instant.
        prewarmSettingsHelper()

        if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            showOnboarding()
        }

        if environment["HEYBAR_CAPTURE_SETTINGS"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.showSettings()
            }
        }
        if environment["HEYBAR_CAPTURE_QUICK_CONTROLS"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.statusBarController?.presentQuickPanelForCapture()
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if isSettingsHelper {
            showSettingsWindow()
        } else {
            showSettings()
        }
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let settingsHelperObserver {
            DistributedNotificationCenter.default().removeObserver(settingsHelperObserver)
            self.settingsHelperObserver = nil
        }
        if let mainAppTerminationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(mainAppTerminationObserver)
            self.mainAppTerminationObserver = nil
        }
        if isSettingsHelper {
            let currentPID = Int(ProcessInfo.processInfo.processIdentifier)
            if UserDefaults.standard.integer(forKey: SettingsHelperState.pidDefaultsKey) == currentPID {
                UserDefaults.standard.removeObject(forKey: SettingsHelperState.pidDefaultsKey)
            }
        }
        statusBarController?.invalidate()
    }

    // MARK: - Settings (main process)

    private func showSettings() {
        let pid = UserDefaults.standard.integer(forKey: SettingsHelperState.pidDefaultsKey)
        let helperAlive = pid > 0
            && pid != Int(ProcessInfo.processInfo.processIdentifier)
            && NSRunningApplication(processIdentifier: pid_t(pid)) != nil
        if helperAlive {
            DistributedNotificationCenter.default().postNotificationName(
                SettingsHelperState.showNotificationName,
                object: Bundle.main.bundleIdentifier,
                userInfo: nil,
                deliverImmediately: true
            )
        } else {
            // Helper not ready yet (e.g. clicked before pre-warm finished) — launch directly.
            launchSettingsHelper(standby: false)
        }
    }

    /// Launch the helper process ahead of time so the first Settings open is instant.
    private func prewarmSettingsHelper() {
        launchSettingsHelper(standby: true)
    }

    private func launchSettingsHelper(standby: Bool) {
        guard let executableURL = Bundle.main.executableURL else { return }
        let process = Process()
        process.executableURL = executableURL
        process.qualityOfService = .userInteractive
        var env = ProcessInfo.processInfo.environment
        env[SettingsHelperState.environmentKey] = "1"
        process.environment = env
        process.arguments = standby
            ? ["--settings-helper", SettingsHelperState.standbyArgument]
            : ["--settings-helper"]
        do {
            try process.run()
        } catch {
            HeyBarDiagnostics.error(HeyBarLog.app, "Failed to launch settings helper: \(error.localizedDescription)")
        }
    }

    // MARK: - Settings (helper process)

    private func showSettingsWindow() {
        // Show Dock icon while Settings is open.
        NSApp.setActivationPolicy(.regular)

        if let existing = settingsWindowController {
            existing.present()
            NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
            return
        }

        let controller = SettingsWindowController(model: model)
        // On close: hide Dock icon but stay alive so the next open is instant.
        controller.onWindowClose = { [weak self] in
            self?.settingsWindowController = nil
            NSApp.setActivationPolicy(.accessory)
        }
        settingsWindowController = controller
        controller.present()
        NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
    }

    // MARK: - Onboarding

    private func showOnboarding() {
        onboardingWindowController = OnboardingWindowController { [weak self] in
            self?.onboardingWindowController?.close()
            self?.onboardingWindowController = nil
        }
        onboardingWindowController?.present()
    }
}
