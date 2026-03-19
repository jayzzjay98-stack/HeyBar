import Foundation

@MainActor
class ScriptedSystemPreferenceController: ObservableObject {
    @Published var isEnabled = false
    @Published var isBusy = false
    @Published var lastError: String?

    private let readScript: String
    private let writeScript: (Bool) -> String
    private let fallbackReadCommand: [String]
    private let scriptExecutor: any AppleScriptExecuting
    private let commandRunner: any SystemCommandRunning

    init(
        readScript: String,
        writeScript: @escaping (Bool) -> String,
        fallbackReadCommand: [String],
        scriptExecutor: any AppleScriptExecuting = AppleScriptExecutor(),
        commandRunner: any SystemCommandRunning = SystemCommandRunner()
    ) {
        self.readScript = readScript
        self.writeScript = writeScript
        self.fallbackReadCommand = fallbackReadCommand
        self.scriptExecutor = scriptExecutor
        self.commandRunner = commandRunner
        refresh()
    }

    func refresh() {
        switch scriptExecutor.run(readScript) {
        case .success(let value):
            isEnabled = SystemPreferenceValue.isEnabled(value)
            lastError = nil
        case .failure(let message):
            let output = commandRunner.run(fallbackReadCommand)
            isEnabled = output.status == 0 ? SystemPreferenceValue.isEnabled(output.stdout) : false
            lastError = message
            HeyBarDiagnostics.error(HeyBarLog.automation, "Scripted refresh fallback used: \(message)")
        }
    }

    func setEnabled(_ enabled: Bool) {
        isBusy = true
        defer { isBusy = false }

        switch scriptExecutor.run(writeScript(enabled)) {
        case .success:
            isEnabled = enabled
            lastError = nil
        case .failure(let scriptError):
            lastError = scriptError
            HeyBarDiagnostics.error(HeyBarLog.automation, scriptError)
        }
    }

    func toggle() {
        setEnabled(!isEnabled)
    }
}
