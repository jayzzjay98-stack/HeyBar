import Foundation

@MainActor
protocol AppleScriptExecuting {
    func run(_ source: String) -> AppleScriptController.ExecutionResult
}

@MainActor
struct AppleScriptExecutor: AppleScriptExecuting {
    func run(_ source: String) -> AppleScriptController.ExecutionResult {
        AppleScriptController.run(source)
    }
}
