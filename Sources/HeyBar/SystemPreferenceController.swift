import Foundation

@MainActor
class SystemPreferenceController: ObservableObject {
    @Published var isEnabled = false
    @Published var isBusy = false
    @Published var lastError: String?

    private let readCommand: [String]
    private let writeCommand: (Bool) -> [String]
    private let applyCommand: [String]
    private let commandRunner: any SystemCommandRunning

    init(
        readCommand: [String],
        writeCommand: @escaping (Bool) -> [String],
        applyCommand: [String],
        commandRunner: any SystemCommandRunning = SystemCommandRunner()
    ) {
        self.readCommand = readCommand
        self.writeCommand = writeCommand
        self.applyCommand = applyCommand
        self.commandRunner = commandRunner
        refresh()
    }

    func refresh() {
        let output = commandRunner.run(readCommand)
        if output.status == 0 {
            isEnabled = SystemPreferenceValue.isEnabled(output.stdout)
            lastError = nil
        } else {
            isEnabled = false
            lastError = nil
            HeyBarDiagnostics.debug(HeyBarLog.systemPreferences, "Refresh fallback: read command failed for \(readCommand.joined(separator: " "))")
        }
    }

    func setEnabled(_ enabled: Bool) {
        isBusy = true
        defer { isBusy = false }

        let writeResult = commandRunner.run(writeCommand(enabled))
        guard writeResult.status == 0 else {
            lastError = writeResult.stderr.trimmedNonEmpty ?? UserFacingMessages.systemPreferenceUpdateFailed
            HeyBarDiagnostics.error(HeyBarLog.systemPreferences, "Write command failed: \(lastError ?? "unknown error")")
            return
        }

        let applyResult = commandRunner.run(applyCommand)
        if applyResult.status == 0 || applyResult.stderr.contains("No matching processes") {
            isEnabled = enabled
            lastError = nil
        } else {
            lastError = applyResult.stderr.trimmedNonEmpty ?? UserFacingMessages.systemPreferenceApplyFailed
            HeyBarDiagnostics.error(HeyBarLog.systemPreferences, "Apply command failed: \(lastError ?? "unknown error")")
        }
    }

    func toggle() {
        setEnabled(!isEnabled)
    }
}
