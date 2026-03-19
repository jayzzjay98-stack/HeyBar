import Foundation

@MainActor
final class HideBarController: ScriptedSystemPreferenceController {
    init(
        scriptExecutor: any AppleScriptExecuting = AppleScriptExecutor(),
        commandRunner: any SystemCommandRunning = SystemCommandRunner()
    ) {
        super.init(
            readScript: """
            tell application "System Events"
                tell dock preferences to get autohide menu bar
            end tell
            """,
            writeScript: { enabled in
                enabled
                    ? """
                    tell application "System Events"
                        tell dock preferences to set autohide menu bar to true
                    end tell
                    """
                    : """
                    tell application "System Events"
                        tell dock preferences to set autohide menu bar to false
                    end tell
                    """
            },
            fallbackReadCommand: ["/usr/bin/defaults", "read", "-g", "_HIHideMenuBar"],
            scriptExecutor: scriptExecutor,
            commandRunner: commandRunner
        )
    }
}
