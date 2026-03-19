@testable import HeyBar

final class MockSystemCommandRunner: SystemCommandRunning {
    var results: [[String]: SystemCommandResult] = [:]

    func run(_ command: [String]) -> SystemCommandResult {
        results[command] ?? SystemCommandResult(status: 1, stdout: "", stderr: "Missing mock result.")
    }
}

@MainActor
final class MockAppleScriptExecutor: AppleScriptExecuting {
    var results: [String: AppleScriptController.ExecutionResult] = [:]
    var defaultResult: AppleScriptController.ExecutionResult = .success("")

    func run(_ source: String) -> AppleScriptController.ExecutionResult {
        results[source] ?? defaultResult
    }
}

final class MockNightShiftBridge: NightShiftManaging {
    var supported = false
    var enabled = false
    var currentStrength: Float = 0.5
    var setEnabledCalls: [Bool] = []
    var setStrengthCalls: [Float] = []

    func isSupported() -> Bool { supported }
    func isEnabled() -> Bool { enabled }
    func strength() -> Float { currentStrength }

    func setEnabled(_ enabled: Bool) -> Bool {
        setEnabledCalls.append(enabled)
        self.enabled = enabled
        return true
    }

    func setStrength(_ strength: Float) -> Bool {
        setStrengthCalls.append(strength)
        currentStrength = strength
        return true
    }
}

final class MockKeyLightBridge: KeyLightManaging {
    var supported = false
    var currentBrightness: Float = 0.6
    var autoBrightnessEnabled = false
    var setBrightnessCalls: [Float] = []
    var setAutoBrightnessCalls: [Bool] = []

    func isSupported() -> Bool { supported }
    func brightness() -> Float { currentBrightness }
    func isAutoBrightnessEnabled() -> Bool { autoBrightnessEnabled }

    func setBrightness(_ brightness: Float) -> Bool {
        setBrightnessCalls.append(brightness)
        currentBrightness = brightness
        return true
    }

    func setAutoBrightnessEnabled(_ enabled: Bool) -> Bool {
        setAutoBrightnessCalls.append(enabled)
        autoBrightnessEnabled = enabled
        return true
    }
}
