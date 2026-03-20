import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = AppModel()
    private var statusBarController: StatusBarController?
    private var settingsWindowController: SettingsWindowController?
    private var onboardingWindowController: OnboardingWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        model.onQuit = { NSApp.terminate(nil) }

        _ = model.shortcuts

        statusBarController = StatusBarController(model: model, settingsHandler: { [weak self] in
            self?.showSettings()
        })
        statusBarController?.setVisible(true)

        if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            showOnboarding()
        }

        let environment = ProcessInfo.processInfo.environment
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
        showSettings()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusBarController?.invalidate()
    }

    // MARK: - Settings

    private func showSettings() {
        // Always recreate so the window opens fresh (avoids stale frame / z-order issues).
        settingsWindowController?.onWindowClose = nil
        settingsWindowController?.close()
        settingsWindowController = nil

        let controller = SettingsWindowController(model: model)
        controller.onWindowClose = { [weak self] in
            self?.settingsWindowController = nil
        }
        settingsWindowController = controller
        controller.present()
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
