import Foundation

@MainActor
final class HiddenFilesController: SystemPreferenceController {
    init(commandRunner: any SystemCommandRunning = SystemCommandRunner()) {
        super.init(
            readCommand: ["/usr/bin/defaults", "read", "com.apple.finder", "AppleShowAllFiles"],
            writeCommand: { enabled in
                ["/usr/bin/defaults", "write", "com.apple.finder", "AppleShowAllFiles", "-bool", enabled ? "true" : "false"]
            },
            applyCommand: ["/usr/bin/killall", "Finder"],
            commandRunner: commandRunner
        )
    }
}
