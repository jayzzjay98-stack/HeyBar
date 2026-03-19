enum UserFacingMessages {
    static let automationPermissionRequired =
        "Allow HeyBar to control System Events in System Settings > Privacy & Security > Automation."
    static let accessibilityPermissionRequired =
        "Allow HeyBar in System Settings > Privacy & Security > Accessibility to start CleanKey mode."
    static let appleScriptExecutionFailed = "AppleScript execution failed."
    static let systemPreferenceUpdateFailed = "Unable to update the system preference."
    static let systemPreferenceApplyFailed = "The updated preference could not be applied."
    static let shortcutUnavailable = "That shortcut is unavailable. Try a different key combination."

    static func savedShortcutCleared(for actionTitle: String) -> String {
        "Saved shortcut for \(actionTitle) was unavailable and has been cleared."
    }

    static func shortcutRestoreFailed(baseMessage: String, restoredTitles: String) -> String {
        "\(baseMessage) Existing shortcuts for \(restoredTitles) could not be restored and were cleared."
    }

    static func launchAtLoginUpdateFailed(_ detail: String) -> String {
        "Launch at Login could not be updated. \(detail)"
    }
}
