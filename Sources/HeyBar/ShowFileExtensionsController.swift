import Foundation

@MainActor
final class ShowFileExtensionsController: SystemPreferenceController {
    init() {
        super.init(
            readCommand: ["/usr/bin/defaults", "read", "NSGlobalDomain", "AppleShowAllExtensions"],
            writeCommand: { enabled in
                ["/usr/bin/defaults", "write", "NSGlobalDomain", "AppleShowAllExtensions", "-bool", enabled ? "true" : "false"]
            },
            applyCommand: ["/usr/bin/killall", "Finder"]
        )
    }
}
