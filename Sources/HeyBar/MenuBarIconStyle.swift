import AppKit

enum MenuBarIconStyle: String, CaseIterable, Identifiable {
    case bar
    case menuBar
    case spark
    case bolt
    case dots

    static let storageKey = "heybar.menuBarIconStyle"
    static let didChangeNotification = Notification.Name("com.gravity.heybar.menuBarIconStyleDidChange")

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bar:     return "Bar"
        case .menuBar: return "Menu Bar"
        case .spark:   return "Spark"
        case .bolt:    return "Bolt"
        case .dots:    return "Dots"
        }
    }

    var previewSymbolName: String {
        switch self {
        case .bar:     return "line.diagonal"
        case .menuBar: return "menubar.rectangle"
        case .spark:   return "sparkles"
        case .bolt:    return "bolt"
        case .dots:    return "ellipsis"
        }
    }

    var statusSymbolName: String? {
        switch self {
        case .bar:     return nil
        case .menuBar: return "menubar.rectangle"
        case .spark:   return "sparkles"
        case .bolt:    return "bolt"
        case .dots:    return "ellipsis"
        }
    }

    var accessibilityDescription: String {
        "HeyBar \(title) menu bar icon"
    }
}

struct MenuBarIconStyleStore {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = MenuBarIconStyle.storageKey) {
        self.defaults = defaults
        self.key = key
    }

    func load() -> MenuBarIconStyle {
        guard let rawValue = defaults.string(forKey: key),
              let style = MenuBarIconStyle(rawValue: rawValue)
        else { return .bar }
        return style
    }

    func save(_ style: MenuBarIconStyle) {
        defaults.set(style.rawValue, forKey: key)
        DistributedNotificationCenter.default().postNotificationName(
            MenuBarIconStyle.didChangeNotification,
            object: Bundle.main.bundleIdentifier,
            userInfo: nil,
            deliverImmediately: true
        )
    }
}
