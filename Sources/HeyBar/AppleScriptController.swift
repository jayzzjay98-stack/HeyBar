import Foundation
import OSAKit

@MainActor
enum AppleScriptController {
    private enum AutomationError {
        static let notAuthorized = -1743
        static let eventNotPermitted = -1744
        static let targetUnavailable = -10827
    }

    enum ExecutionResult {
        case success(String)
        case failure(String)
    }

    static func run(_ source: String) -> ExecutionResult {
        var error: NSDictionary?
        let script = OSAScript(source: source)

        if let descriptor = script.executeAndReturnError(&error) {
            HeyBarDiagnostics.debug(HeyBarLog.automation, "AppleScript executed successfully.")
            if let stringValue = descriptor.stringValue {
                return .success(stringValue)
            }
            return .success("")
        }

        let errorNumber = error?[NSAppleScript.errorNumber] as? Int
        if errorNumber == AutomationError.notAuthorized
            || errorNumber == AutomationError.eventNotPermitted
            || errorNumber == AutomationError.targetUnavailable {
            HeyBarDiagnostics.error(HeyBarLog.automation, "AppleScript automation permission error: \(errorNumber ?? 0)")
            return .failure(UserFacingMessages.automationPermissionRequired)
        }

        let message = (error?[NSAppleScript.errorMessage] as? String)
            ?? (error?.description ?? UserFacingMessages.appleScriptExecutionFailed)
        HeyBarDiagnostics.error(HeyBarLog.automation, "AppleScript failed: \(message)")
        return .failure(message)
    }
}
