import Foundation

struct SystemCommandResult {
    let status: Int32
    let stdout: String
    let stderr: String
}

protocol SystemCommandRunning {
    func run(_ command: [String]) -> SystemCommandResult
}

struct SystemCommandRunner: SystemCommandRunning {
    func run(_ command: [String]) -> SystemCommandResult {
        guard let launchPath = command.first else {
            return SystemCommandResult(status: 1, stdout: "", stderr: "Missing executable path.")
        }

        HeyBarDiagnostics.debug(HeyBarLog.systemPreferences, "Running command: \(command.joined(separator: " "))")

        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = Array(command.dropFirst())
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            HeyBarDiagnostics.error(HeyBarLog.systemPreferences, "Command failed to launch: \(error.localizedDescription)")
            return SystemCommandResult(status: 1, stdout: "", stderr: error.localizedDescription)
        }

        let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        HeyBarDiagnostics.debug(
            HeyBarLog.systemPreferences,
            "Command finished with status \(process.terminationStatus). stdout=\(stdout.trimmingCharacters(in: .whitespacesAndNewlines)) stderr=\(stderr.trimmingCharacters(in: .whitespacesAndNewlines))"
        )
        return SystemCommandResult(status: process.terminationStatus, stdout: stdout, stderr: stderr)
    }
}

enum SystemPreferenceValue {
    static func isEnabled(_ rawValue: String) -> Bool {
        let normalized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized == "1" || normalized == "true" || normalized == "yes"
    }
}

extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
