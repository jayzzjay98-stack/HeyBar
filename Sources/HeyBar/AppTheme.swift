import AppKit
import SwiftUI

struct AppTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let symbolName: String
    let panelGradient: [NSColor]
    let tileGradient: [NSColor]
    let tileSecondaryGradient: [NSColor]
    let panelBorder: NSColor
    let titleColor: NSColor
    let bodyColor: NSColor
    let closeFill: NSColor
    let closeTint: NSColor
    let settingsFill: NSColor
    let settingsTint: NSColor
    let badgeOnFill: NSColor
    let badgeOnText: NSColor
    let badgeOffFill: NSColor
    let badgeOffText: NSColor
    let titleFontName: String
    let cardFontName: String

    var titleFontLabel: String {
        ThemeCatalog.displayName(forFontName: titleFontName)
    }

    var cardFontLabel: String {
        ThemeCatalog.displayName(forFontName: cardFontName)
    }

    var fontPairLabel: String {
        "\(titleFontLabel) + \(cardFontLabel)"
    }

    var schemeLabel: String {
        preferredColorScheme == .dark ? "Dark UI" : "Light UI"
    }

    var swiftUIPanelGradient: LinearGradient {
        LinearGradient(
            colors: panelGradient.map(Color.init(nsColor:)),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var swiftUITileGradient: LinearGradient {
        LinearGradient(
            colors: tileGradient.map(Color.init(nsColor:)),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var titleFont: NSFont {
        NSFont(name: titleFontName, size: 17) ?? .systemFont(ofSize: 17, weight: .bold)
    }

    var cardFont: NSFont {
        NSFont(name: cardFontName, size: 13) ?? .systemFont(ofSize: 13, weight: .bold)
    }

    var settingsFont: NSFont {
        NSFont(name: cardFontName, size: 12) ?? .systemFont(ofSize: 12, weight: .semibold)
    }

    var settingsPageTitleFont: NSFont {
        NSFont(name: titleFontName, size: 24) ?? .systemFont(ofSize: 24, weight: .bold)
    }

    var settingsSectionTitleFont: NSFont {
        NSFont(name: cardFontName, size: 16) ?? .systemFont(ofSize: 16, weight: .semibold)
    }

    var settingsBodyFont: NSFont {
        NSFont(name: cardFontName, size: 12) ?? .systemFont(ofSize: 12, weight: .medium)
    }

    var settingsLabelFont: NSFont {
        NSFont(name: cardFontName, size: 11) ?? .systemFont(ofSize: 11, weight: .bold)
    }

    var settingsPillFont: NSFont {
        NSFont(name: cardFontName, size: 11) ?? .systemFont(ofSize: 11, weight: .semibold)
    }

    var quickControlsButtonFont: NSFont {
        NSFont(name: cardFontName, size: 12) ?? .systemFont(ofSize: 12, weight: .semibold)
    }

    var quickControlsTileTitleFont: NSFont {
        NSFont(name: titleFontName, size: 13) ?? .systemFont(ofSize: 13, weight: .bold)
    }

    var quickControlsTileCaptionFont: NSFont {
        NSFont(name: cardFontName, size: 10) ?? .systemFont(ofSize: 10, weight: .bold)
    }

    var quickControlsBadgeFont: NSFont {
        NSFont(name: cardFontName, size: 10) ?? .systemFont(ofSize: 10, weight: .bold)
    }

    var preferredColorScheme: ColorScheme {
        averageLuminance(of: panelGradient) < 0.5 ? .dark : .light
    }

    var settingsPrimaryTextColor: NSColor {
        preferredColorScheme == .dark ? ThemeCatalog.hex(0xEAF2EF) : ThemeCatalog.hex(0x162521)
    }

    var settingsSecondaryTextColor: NSColor {
        preferredColorScheme == .dark ? ThemeCatalog.hex(0xA9BAB4) : ThemeCatalog.hex(0x60736D)
    }

    var settingsWindowGradientColors: [NSColor] {
        if preferredColorScheme == .dark {
            return [
                blended(settingsTint, with: ThemeCatalog.hex(0x0D1211), amount: 0.82),
                blended(panelGradient.last ?? closeFill, with: ThemeCatalog.hex(0x101715), amount: 0.78)
            ]
        }

        return [
            blended(settingsTint, with: .white, amount: 0.84),
            blended(closeFill, with: ThemeCatalog.hex(0xEEF3F1), amount: 0.34)
        ]
    }

    var settingsSidebarSurfaceColor: NSColor {
        if preferredColorScheme == .dark {
            return blended(settingsTint, with: ThemeCatalog.hex(0x151D1A), amount: 0.84, alpha: 0.96)
        }

        return blended(settingsFill, with: .white, amount: 0.58, alpha: 0.96)
    }

    var settingsDetailSurfaceColor: NSColor {
        if preferredColorScheme == .dark {
            return blended(settingsTint, with: ThemeCatalog.hex(0x18211E), amount: 0.9, alpha: 0.38)
        }

        return blended(settingsTint, with: ThemeCatalog.hex(0xF4F8F6), amount: 0.84, alpha: 0.92)
    }

    var settingsContentSurfaceColor: NSColor {
        if preferredColorScheme == .dark {
            return blended(settingsFill, with: ThemeCatalog.hex(0x101715), amount: 0.9, alpha: 0.97)
        }

        return blended(settingsFill, with: .white, amount: 0.82, alpha: 0.97)
    }

    var settingsChromeSurfaceColor: NSColor {
        if preferredColorScheme == .dark {
            return blended(settingsTint, with: ThemeCatalog.hex(0x1A2320), amount: 0.88, alpha: 0.96)
        }

        return blended(settingsTint, with: ThemeCatalog.hex(0xF4F8F6), amount: 0.82, alpha: 0.96)
    }

    var settingsSectionSurfaceColor: NSColor {
        if preferredColorScheme == .dark {
            return blended(settingsFill, with: ThemeCatalog.hex(0x161F1C), amount: 0.88, alpha: 0.98)
        }

        return blended(settingsFill, with: .white, amount: 0.84, alpha: 0.98)
    }

    var settingsSeparatorColor: NSColor {
        preferredColorScheme == .dark
            ? blended(settingsTint, with: ThemeCatalog.hex(0x2A3632), amount: 0.86, alpha: 0.8)
            : blended(settingsTint, with: ThemeCatalog.hex(0xD9E3DF), amount: 0.92, alpha: 0.9)
    }

    var settingsSidebarBorderColor: NSColor {
        preferredColorScheme == .dark
            ? blended(settingsTint, with: ThemeCatalog.hex(0x2B3532), amount: 0.84, alpha: 0.9)
            : blended(settingsTint, with: ThemeCatalog.hex(0xD7E1DD), amount: 0.9, alpha: 0.95)
    }

    var settingsAccentSoftFill: NSColor {
        blended(settingsTint, with: preferredColorScheme == .dark ? ThemeCatalog.hex(0x0E1312) : .white, amount: preferredColorScheme == .dark ? 0.72 : 0.82, alpha: preferredColorScheme == .dark ? 0.34 : 0.62)
    }

    var settingsInteractiveHoverFill: NSColor {
        blended(settingsTint, with: preferredColorScheme == .dark ? ThemeCatalog.hex(0x17201D) : .white, amount: preferredColorScheme == .dark ? 0.72 : 0.86, alpha: preferredColorScheme == .dark ? 0.28 : 0.78)
    }

    var settingsInteractivePressedFill: NSColor {
        blended(settingsTint, with: preferredColorScheme == .dark ? ThemeCatalog.hex(0x131B19) : ThemeCatalog.hex(0xEEF4F1), amount: preferredColorScheme == .dark ? 0.66 : 0.8, alpha: preferredColorScheme == .dark ? 0.34 : 0.88)
    }

    var settingsSelectedFill: NSColor {
        blended(settingsTint, with: preferredColorScheme == .dark ? ThemeCatalog.hex(0x111715) : .white, amount: preferredColorScheme == .dark ? 0.66 : 0.78, alpha: preferredColorScheme == .dark ? 0.38 : 0.9)
    }

    var settingsSelectedBorderColor: NSColor {
        blended(settingsTint, with: preferredColorScheme == .dark ? ThemeCatalog.hex(0x293430) : ThemeCatalog.hex(0xD3DFD9), amount: preferredColorScheme == .dark ? 0.62 : 0.76, alpha: preferredColorScheme == .dark ? 0.92 : 0.96)
    }

    var settingsDisabledSurfaceColor: NSColor {
        blended(settingsFill, with: preferredColorScheme == .dark ? ThemeCatalog.hex(0x0F1513) : ThemeCatalog.hex(0xF4F7F5), amount: preferredColorScheme == .dark ? 0.82 : 0.9, alpha: preferredColorScheme == .dark ? 0.9 : 0.92)
    }

    var settingsDisabledTextColor: NSColor {
        preferredColorScheme == .dark ? ThemeCatalog.hex(0x7E8B86) : ThemeCatalog.hex(0x7B8B84)
    }

    var quickControlEnabledFill: NSColor {
        // Use the per-theme badge colour so every theme looks intentional
        badgeOnFill
    }

    var quickControlEnabledTextColor: NSColor {
        badgeOnText
    }

    var quickControlOffFill: NSColor {
        unifiedTileForegroundColor.withAlphaComponent(0.16)
    }

    var quickControlOffTextColor: NSColor {
        unifiedTileForegroundColor.withAlphaComponent(0.82)
    }

    var quickControlDisabledFill: NSColor {
        unifiedTileForegroundColor.withAlphaComponent(0.10)
    }

    var quickControlDisabledTextColor: NSColor {
        unifiedTileForegroundColor.withAlphaComponent(0.42)
    }

    var settingsErrorTextColor: NSColor {
        preferredColorScheme == .dark ? ThemeCatalog.hex(0xFFB4AB) : ThemeCatalog.hex(0xB3261E)
    }

    var settingsHeroGradientColors: [NSColor] {
        if preferredColorScheme == .dark {
            return [
                tileGradient.first ?? closeFill,
                tileSecondaryGradient.last ?? settingsFill,
                ThemeCatalog.hex(0x161B18)
            ]
        }

        return [
            darkened(tileGradient.first ?? closeFill, amount: 0.28),
            darkened(tileGradient.last ?? settingsFill, amount: 0.2),
            darkened(tileSecondaryGradient.last ?? settingsFill, amount: 0.24)
        ]
    }

    var settingsHeroTextColor: NSColor {
        contrastTextColor(for: settingsHeroGradientColors)
    }

    var unifiedTileForegroundColor: NSColor {
        contrastTextColor(for: tileGradient + tileSecondaryGradient)
    }

    func tileForegroundColor(alternate: Bool) -> NSColor {
        contrastTextColor(for: alternate ? tileSecondaryGradient : tileGradient)
    }

    func badgeTextColor(for styleIsOn: Bool) -> NSColor {
        styleIsOn ? badgeOnText : badgeOffText
    }

    private func contrastTextColor(for colors: [NSColor]) -> NSColor {
        averageLuminance(of: colors) < 0.56 ? .white : ThemeCatalog.hex(0x1E1E1E)
    }

    private func darkened(_ color: NSColor, amount: CGFloat) -> NSColor {
        let rgb = color.usingColorSpace(.deviceRGB) ?? color
        return NSColor(
            calibratedRed: max(rgb.redComponent - amount, 0),
            green: max(rgb.greenComponent - amount, 0),
            blue: max(rgb.blueComponent - amount, 0),
            alpha: rgb.alphaComponent
        )
    }

    private func blended(_ color: NSColor, with other: NSColor, amount: CGFloat, alpha: CGFloat? = nil) -> NSColor {
        let lhs = (color.usingColorSpace(.deviceRGB) ?? color)
        let rhs = (other.usingColorSpace(.deviceRGB) ?? other)
        let clampedAmount = max(0, min(amount, 1))

        return NSColor(
            calibratedRed: lhs.redComponent + ((rhs.redComponent - lhs.redComponent) * clampedAmount),
            green: lhs.greenComponent + ((rhs.greenComponent - lhs.greenComponent) * clampedAmount),
            blue: lhs.blueComponent + ((rhs.blueComponent - lhs.blueComponent) * clampedAmount),
            alpha: alpha ?? lhs.alphaComponent
        )
    }

    private func averageLuminance(of colors: [NSColor]) -> CGFloat {
        guard !colors.isEmpty else { return 0.5 }
        let values = colors.map(\.perceivedLuminance)
        return values.reduce(0, +) / CGFloat(values.count)
    }
}

private extension NSColor {
    var perceivedLuminance: CGFloat {
        let rgb = usingColorSpace(.deviceRGB) ?? self
        return (0.299 * rgb.redComponent) + (0.587 * rgb.greenComponent) + (0.114 * rgb.blueComponent)
    }
}
