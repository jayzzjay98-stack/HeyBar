import AppKit
import Foundation

enum ThemeCatalog {
    static let storageKey = "heybar.selectedTheme"
    static let legacyStorageKey = "peekaboo.selectedTheme"

    static let fallbackTheme = themes[0]

    static func persistedThemeID(defaults: UserDefaults = .standard) -> String? {
        if let themeID = defaults.string(forKey: storageKey) {
            return themeID
        }

        guard let legacyThemeID = defaults.string(forKey: legacyStorageKey) else {
            return nil
        }

        defaults.set(legacyThemeID, forKey: storageKey)
        defaults.removeObject(forKey: legacyStorageKey)
        return legacyThemeID
    }

    static func theme(for id: String) -> AppTheme {
        themes.first(where: { $0.id == id }) ?? fallbackTheme
    }

    static func preferredFontName(_ candidates: String..., fallback: String) -> String {
        for candidate in candidates where NSFont(name: candidate, size: 14) != nil {
            return candidate
        }
        return fallback
    }

    static func displayName(forFontName name: String) -> String {
        name
            .replacingOccurrences(of: "AvenirNext", with: "Avenir Next")
            .replacingOccurrences(of: "HelveticaNeue", with: "Helvetica Neue")
            .replacingOccurrences(of: "GillSans", with: "Gill Sans")
            .replacingOccurrences(of: "HoeflerText", with: "Hoefler Text")
            .replacingOccurrences(of: "AmericanTypewriter", with: "American Typewriter")
            .replacingOccurrences(of: "ChalkboardSE", with: "Chalkboard SE")
            .replacingOccurrences(of: "TrebuchetMS", with: "Trebuchet MS")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: " ExtraBlack", with: " Extra Black")
            .replacingOccurrences(of: "BlackItalic", with: " Black Italic")
            .replacingOccurrences(of: "BoldItalic", with: " Bold Italic")
            .replacingOccurrences(of: "SemiBold", with: " Semibold")
            .replacingOccurrences(of: "Heavy", with: "Heavy")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func hex(_ value: UInt32, alpha: CGFloat = 1) -> NSColor {
        let red = CGFloat((value >> 16) & 0xFF) / 255
        let green = CGFloat((value >> 8) & 0xFF) / 255
        let blue = CGFloat(value & 0xFF) / 255
        return NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
    }
}
