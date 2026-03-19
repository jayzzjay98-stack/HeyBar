import AppKit
import Foundation

enum StatusBarClickAction {
    case toggleHiddenMode
    case toggleQuickPanel
}

struct StatusBarBehavior {
    private static let menuBarActivationPadding: CGFloat = 4

    static func action(for event: NSEvent?) -> StatusBarClickAction {
        let isRightClick = event?.type == .rightMouseUp
            || event?.type == .otherMouseUp
            || (event?.type == .leftMouseUp && event?.modifierFlags.contains(.control) == true)

        return isRightClick ? .toggleHiddenMode : .toggleQuickPanel
    }

    static func shouldRevealHiddenMode(
        mouseLocation: NSPoint,
        screenFrames: [CGRect],
        fallbackScreenFrame: CGRect?,
        menuBarThickness: CGFloat
    ) -> Bool {
        let screenFrame = screenFrames.first(where: { $0.contains(mouseLocation) }) ?? fallbackScreenFrame
        guard let screenFrame else { return false }
        return mouseLocation.y >= screenFrame.maxY - menuBarThickness - menuBarActivationPadding
    }
}

final class StatusBarHiddenModeStore {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "isHiddenModeEnabled") {
        self.defaults = defaults
        self.key = key
    }

    func load() -> Bool {
        defaults.bool(forKey: key)
    }

    func save(_ isHidden: Bool) {
        defaults.set(isHidden, forKey: key)
    }
}
