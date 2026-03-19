enum SettingsPage: String, CaseIterable, Identifiable {
    case general     = "Customize"
    case preferences = "Preferences"
    case themes      = "Themes"
    case shortcuts   = "Shortcuts"
    case about       = "About"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .general:      return "slider.horizontal.3"
        case .preferences:  return "gearshape"
        case .themes:       return "swatchpalette"
        case .shortcuts:    return "command"
        case .about:        return "sparkles.rectangle.stack"
        }
    }

    var eyebrow: String {
        switch self {
        case .general:      return "Customize Studio"
        case .preferences:  return "App Configuration"
        case .themes:       return "Visual Direction"
        case .shortcuts:    return "Command Matrix"
        case .about:        return "Product Confidence"
        }
    }

    var summary: String {
        switch self {
        case .general:
            return "Personalize startup, cleaning, Finder, display, and automation controls in one organized workspace."
        case .preferences:
            return "Manage startup behaviour and app-level preferences for HeyBar."
        case .themes:
            return "Curated visual styles for the panel and settings experience, presented like a product gallery."
        case .shortcuts:
            return "Global commands with clearer hierarchy, conflict handling, and a layout that feels intentional."
        case .about:
            return "Version details, release confidence, platform caveats, and support posture in one place."
        }
    }

    var sidebarCaption: String {
        switch self {
        case .general:      return "Custom"
        case .preferences:  return "Prefs"
        case .themes:       return "Gallery"
        case .shortcuts:    return "Keys"
        case .about:        return "Info"
        }
    }

    var commandShortcut: String {
        switch self {
        case .general:      return "1"
        case .preferences:  return "2"
        case .themes:       return "3"
        case .shortcuts:    return "4"
        case .about:        return "5"
        }
    }
}
