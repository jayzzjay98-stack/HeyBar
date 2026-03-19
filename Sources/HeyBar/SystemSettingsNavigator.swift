import AppKit

@MainActor
enum SystemSettingsNavigator {
    static func openAutomationPrivacy() {
        openFirstAvailable([
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Automation",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
        ])
    }

    static func openDisplays() {
        openFirstAvailable([
            "x-apple.systempreferences:com.apple.Displays-Settings.extension",
            "x-apple.systempreferences:com.apple.preference.displays"
        ])
    }

    static func openKeyboard() {
        openFirstAvailable([
            "x-apple.systempreferences:com.apple.Keyboard-Settings.extension",
            "x-apple.systempreferences:com.apple.preference.keyboard"
        ])
    }

    static func openAccessibilityPrivacy() {
        openFirstAvailable([
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ])
    }

    private static func openFirstAvailable(_ urlStrings: [String]) {
        for urlString in urlStrings {
            guard let url = URL(string: urlString) else { continue }
            if NSWorkspace.shared.open(url) {
                return
            }
        }

        if let fallbackURL = URL(string: "x-apple.systempreferences:") {
            _ = NSWorkspace.shared.open(fallbackURL)
        }
    }
}
