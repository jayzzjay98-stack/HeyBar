import AppKit

enum MenuBarIconStyle: String, CaseIterable, Identifiable {
    case bar
    case menuBar
    case spark
    case bolt
    case dots
    case heart
    case star
    case moon
    case cloud
    case leaf
    case smile
    case gift
    case sun

    static let storageKey = "heybar.menuBarIconStyle"
    static let didChangeNotification = Notification.Name("com.gravity.heybar.menuBarIconStyleDidChange")
    static let notificationStyleKey = "style"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bar:     return "Bar"
        case .menuBar: return "Menu Bar"
        case .spark:   return "Spark"
        case .bolt:    return "Bolt"
        case .dots:    return "Dots"
        case .heart:   return "Heart"
        case .star:    return "Star"
        case .moon:    return "Moon"
        case .cloud:   return "Cloud"
        case .leaf:    return "Leaf"
        case .smile:   return "Smile"
        case .gift:    return "Gift"
        case .sun:     return "Sun"
        }
    }

    var previewSymbolName: String {
        switch self {
        case .bar:     return "line.diagonal"
        case .menuBar: return "rectangle.topthird.inset.filled"
        case .spark:   return "sparkle"
        case .bolt:    return "bolt"
        case .dots:    return "ellipsis"
        case .heart:   return "heart"
        case .star:    return "star"
        case .moon:    return "moon"
        case .cloud:   return "cloud"
        case .leaf:    return "leaf"
        case .smile:   return "face.smiling"
        case .gift:    return "gift"
        case .sun:     return "sun.max"
        }
    }

    var statusSymbolName: String? {
        switch self {
        case .bar:     return nil
        case .menuBar: return "rectangle.topthird.inset.filled"
        case .spark:   return "sparkle"
        case .bolt:    return "bolt"
        case .dots:    return "ellipsis"
        case .heart:   return "heart"
        case .star:    return "star"
        case .moon:    return "moon"
        case .cloud:   return "cloud"
        case .leaf:    return "leaf"
        case .smile:   return "face.smiling"
        case .gift:    return "gift"
        case .sun:     return "sun.max"
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
        defaults.synchronize()
        guard let rawValue = defaults.string(forKey: key),
              let style = MenuBarIconStyle(rawValue: rawValue)
        else { return .bar }
        return style
    }

    func save(_ style: MenuBarIconStyle) {
        defaults.set(style.rawValue, forKey: key)
        defaults.synchronize()
        DistributedNotificationCenter.default().postNotificationName(
            MenuBarIconStyle.didChangeNotification,
            object: nil,
            userInfo: [MenuBarIconStyle.notificationStyleKey: style.rawValue],
            deliverImmediately: true
        )
    }
}
