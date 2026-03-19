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

        settingsWindowController = SettingsWindowController(model: model)

        statusBarController = StatusBarController(model: model, settingsHandler: { [weak self] in
            self?.showSettings()
        })

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

    private func showSettings() {
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.present()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showOnboarding() {
        onboardingWindowController = OnboardingWindowController { [weak self] in
            self?.onboardingWindowController?.close()
            self?.onboardingWindowController = nil
        }
        onboardingWindowController?.present()
    }
}
