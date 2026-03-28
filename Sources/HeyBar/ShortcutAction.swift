import Foundation

enum ShortcutAction: String, CaseIterable, Identifiable {
    case keepAwake
    case cleanKey
    case showHiddenFiles
    case showFileExtensions
    case keyLight
    case nightShift
    case hideDock
    case hideBar
    case showDesktop

    var id: String { rawValue }

    var title: String {
        switch self {
        case .keepAwake:
            return "Keep Awake"
        case .cleanKey:
            return "CleanKey"
        case .showHiddenFiles:
            return "Show Hidden Files"
        case .showFileExtensions:
            return "Show File Extensions"
        case .keyLight:
            return "Key Light"
        case .nightShift:
            return "Night Shift"
        case .hideDock:
            return "Hide Dock"
        case .hideBar:
            return "Hide Bar"
        case .showDesktop:
            return "Show Desktop"
        }
    }

    var hotKeyID: UInt32 {
        switch self {
        case .keepAwake:
            return 1
        case .cleanKey:
            return 8
        case .showHiddenFiles:
            return 2
        case .showFileExtensions:
            return 7
        case .keyLight:
            return 3
        case .nightShift:
            return 4
        case .hideDock:
            return 5
        case .hideBar:
            return 6
        case .showDesktop:
            return 9
        }
    }

    var storageKey: String {
        "shortcut.\(rawValue)"
    }
}
