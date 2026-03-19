import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private enum SettingsHelperState {
        static let environmentKey = "HEYBAR_SETTINGS_HELPER"
        static let pidDefaultsKey = "heybar.settingsHelperPID"
        static let showNotificationName = Notification.Name("com.gravity.heybar.settingsHelper.show")
    }

    private let model = AppModel()
    private var statusBarController: StatusBarController?
    private var settingsWindowController: SettingsWindowController?
    private var onboardingWindowController: OnboardingWindowController?
    private var settingsHelperObserver: NSObjectProtocol?
    private let isSettingsHelper =
        ProcessInfo.processInfo.environment[SettingsHelperState.environmentKey] == "1"
        || ProcessInfo.processInfo.arguments.contains("--settings-helper")

    func applicationDidFinishLaunching(_ notification: Notification) {
        model.onQuit = { NSApp.terminate(nil) }

        let environment = ProcessInfo.processInfo.environment
        if isSettingsHelper {
            UserDefaults.standard.set(ProcessInfo.processInfo.processIdentifier, forKey: SettingsHelperState.pidDefaultsKey)
            // showSettingsWindow() owns the full window lifecycle (create → present → onClose).
            // Do NOT pre-create settingsWindowController here: showSettingsWindow() calls .close()
            // on any existing controller first, which would fire onWindowClose → NSApp.terminate
            // before the window ever appears.
            settingsHelperObserver = DistributedNotificationCenter.default().addObserver(
                forName: SettingsHelperState.showNotificationName,
                object: Bundle.main.bundleIdentifier,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.showSettingsWindow()
                }
            }
            showSettingsWindow()
            return
        }

        NSApp.setActivationPolicy(.accessory)

        _ = model.shortcuts

        statusBarController = StatusBarController(model: model, settingsHandler: { [weak self] in
            self?.showSettings()
        })
        statusBarController?.setVisible(true)

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
        if isSettingsHelper {
            let currentPID = Int(ProcessInfo.processInfo.processIdentifier)
            if UserDefaults.standard.integer(forKey: SettingsHelperState.pidDefaultsKey) == currentPID {
                UserDefaults.standard.removeObject(forKey: SettingsHelperState.pidDefaultsKey)
            }
        }
        statusBarController?.invalidate()
    }

    private func showSettings() {
        if activateExistingSettingsHelper() {
            return
        }
        launchSettingsHelper()
    }

    private func showSettingsWindow() {
        // Clear onWindowClose BEFORE closing: otherwise the existing handler
        // ({ NSApp.terminate }) fires during .close(), killing the helper
        // before the new window is ever shown.
        settingsWindowController?.onWindowClose = nil
        settingsWindowController?.close()
        settingsWindowController = nil

        let controller = SettingsWindowController(model: model)
        controller.onWindowClose = { [weak self] in
            self?.settingsWindowController = nil
            NSApp.terminate(nil)
        }
        settingsWindowController = controller
        controller.present()
        NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
    }

    private func activateExistingSettingsHelper() -> Bool {
        let pid = UserDefaults.standard.integer(forKey: SettingsHelperState.pidDefaultsKey)
        guard pid > 0, pid != ProcessInfo.processInfo.processIdentifier,
              NSRunningApplication(processIdentifier: pid_t(pid)) != nil else {
            UserDefaults.standard.removeObject(forKey: SettingsHelperState.pidDefaultsKey)
            return false
        }
        DistributedNotificationCenter.default().postNotificationName(
            SettingsHelperState.showNotificationName,
            object: Bundle.main.bundleIdentifier,
            userInfo: nil,
            deliverImmediately: true
        )
        return true
    }

    private func launchSettingsHelper() {
        guard let executableURL = Bundle.main.executableURL else { return }
        let process = Process()
        process.executableURL = executableURL
        process.qualityOfService = .userInteractive
        var environment = ProcessInfo.processInfo.environment
        environment[SettingsHelperState.environmentKey] = "1"
        process.environment = environment
        process.arguments = ["--settings-helper"]
        do {
            try process.run()
        } catch {
            HeyBarDiagnostics.error(HeyBarLog.app, "Failed to launch settings helper: \(error.localizedDescription)")
        }
    }

    private func showOnboarding() {
        onboardingWindowController = OnboardingWindowController { [weak self] in
            self?.onboardingWindowController?.close()
            self?.onboardingWindowController = nil
        }
        onboardingWindowController?.present()
    }
}
