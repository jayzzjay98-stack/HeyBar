import Foundation
import OSLog

enum HeyBarLog {
    static let app = Logger(subsystem: "com.gravity.heybar", category: "app")
    static let shortcuts = Logger(subsystem: "com.gravity.heybar", category: "shortcuts")
    static let automation = Logger(subsystem: "com.gravity.heybar", category: "automation")
    static let systemPreferences = Logger(subsystem: "com.gravity.heybar", category: "system-preferences")
}

enum HeyBarDiagnostics {
    private static let debugLoggingKey = "heybar.debugLogging"

    static var isDebugLoggingEnabled: Bool {
        let environment = ProcessInfo.processInfo.environment["HEYBAR_DEBUG_LOGGING"]
        return environment == "1" || UserDefaults.standard.bool(forKey: debugLoggingKey)
    }

    static func debug(_ logger: Logger, _ message: String) {
        guard isDebugLoggingEnabled else { return }
        logger.debug("\(message, privacy: .public)")
    }

    static func error(_ logger: Logger, _ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
