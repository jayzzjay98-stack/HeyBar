import Foundation

@MainActor
final class HideDockController: ScriptedSystemPreferenceController {
    init(
        scriptExecutor: any AppleScriptExecuting = AppleScriptExecutor(),
        commandRunner: any SystemCommandRunning = SystemCommandRunner()
    ) {
        super.init(
            readScript: #"tell application "System Events" to get the autohide of the dock preferences"#,
            writeScript: { enabled in
                enabled
                    ? #"tell application "System Events" to set the autohide of the dock preferences to true"#
                    : #"tell application "System Events" to set the autohide of the dock preferences to false"#
            },
            fallbackReadCommand: ["/usr/bin/defaults", "read", "com.apple.dock", "autohide"],
            scriptExecutor: scriptExecutor,
            commandRunner: commandRunner
        )
    }
}
