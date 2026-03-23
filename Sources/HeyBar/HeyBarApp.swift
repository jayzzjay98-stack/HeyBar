import AppKit

@main
struct HeyBarApp {
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        // Both main app and helper start as accessory (no Dock icon).
        // The helper switches to .regular when the Settings window opens.
        application.setActivationPolicy(.accessory)
        application.delegate = delegate
        application.run()
    }
}
