import AppKit

@main
struct HeyBarApp {
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        let environment = ProcessInfo.processInfo.environment
        let arguments = ProcessInfo.processInfo.arguments
        let isSettingsHelper = environment["HEYBAR_SETTINGS_HELPER"] == "1" || arguments.contains("--settings-helper")

        application.setActivationPolicy(isSettingsHelper ? .regular : .accessory)
        application.delegate = delegate
        application.run()
    }
}
