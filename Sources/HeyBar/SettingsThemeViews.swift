import AppKit
import SwiftUI

struct SettingsWindowBackground: View {
    let theme: AppTheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: theme.settingsWindowGradientColors.map(Color.init(nsColor:)),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color(nsColor: theme.settingsTint).opacity(theme.preferredColorScheme == .dark ? 0.22 : 0.16),
                    .clear
                ],
                center: .topLeading,
                startRadius: 20,
                endRadius: 260
            )

            RadialGradient(
                colors: [
                    Color(nsColor: theme.closeFill).opacity(theme.preferredColorScheme == .dark ? 0.16 : 0.12),
                    .clear
                ],
                center: .bottomTrailing,
                startRadius: 40,
                endRadius: 240
            )
        }
    }
}

struct SettingsSidebar<Content: View>: View {
    let theme: AppTheme
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: SettingsLayout.sidebarCornerRadius, style: .continuous)
                .fill(Color(nsColor: theme.settingsSidebarSurfaceColor))
                .overlay(
                    RoundedRectangle(cornerRadius: SettingsLayout.sidebarCornerRadius, style: .continuous)
                        .stroke(Color(nsColor: theme.settingsSidebarBorderColor), lineWidth: 1)
                )
            content
                .padding(18)
        }
        .frame(width: SettingsLayout.sidebarWidth)
        .padding(.leading, SettingsLayout.shellInset)
        .padding(.top, SettingsLayout.shellInset)
        .padding(.bottom, SettingsLayout.shellInset)
    }
}

struct SettingsDetailSurface<Content: View>: View {
    let theme: AppTheme
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: SettingsLayout.contentCornerRadius, style: .continuous)
                .fill(Color(nsColor: theme.settingsDetailSurfaceColor))
                .overlay(
                    RoundedRectangle(cornerRadius: SettingsLayout.contentCornerRadius, style: .continuous)
                        .stroke(Color(nsColor: theme.settingsSidebarBorderColor).opacity(0.85), lineWidth: 1)
                )
            content.foregroundStyle(Color(nsColor: theme.settingsPrimaryTextColor))
        }
        .padding(.trailing, SettingsLayout.shellInset)
        .padding(.vertical, SettingsLayout.shellInset)
    }
}

struct SettingsContentCard<Content: View>: View {
    let theme: AppTheme
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(nsColor: theme.settingsContentSurfaceColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color(nsColor: theme.settingsSidebarBorderColor).opacity(0.7), lineWidth: 1)
                )

            content
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }
}

struct SettingsBrandLockup: View {
    let theme: AppTheme

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(nsColor: theme.settingsAccentSoftFill))
                Image(systemName: theme.symbolName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(nsColor: theme.settingsTint))
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text("HeyBar")
                    .font(Font(theme.settingsSectionTitleFont))
                    .foregroundStyle(Color(nsColor: theme.settingsPrimaryTextColor))
                Text("Settings Studio")
                    .font(Font(theme.settingsBodyFont))
                    .foregroundStyle(Color(nsColor: theme.settingsSecondaryTextColor))
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(nsColor: theme.settingsChromeSurfaceColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color(nsColor: theme.settingsSidebarBorderColor), lineWidth: 1)
                )
        )
    }
}

struct SettingsSidebarButton: View {
    let theme: AppTheme
    let page: SettingsPage
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(accentColor)
                    .frame(width: 3, height: 24)
                    .opacity(isSelected ? 1 : 0)

                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(iconBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(iconBorderColor, lineWidth: 1)
                        )

                    Image(systemName: page.iconName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(iconForegroundColor)
                }
                .frame(width: 30, height: 30)

                Text(page.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(titleColor)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, SettingsLayout.sidebarRowHorizontalPadding)
            .padding(.vertical, SettingsLayout.sidebarRowVerticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(buttonBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(buttonBorderColor, lineWidth: 1)
                    )
            )
            .shadow(color: shadowColor, radius: isSelected ? 8 : 0, y: isSelected ? 4 : 0)
        }
        .buttonStyle(.plain)
        .keyboardShortcut(KeyEquivalent(Character(page.commandShortcut)), modifiers: [.command])
        .help("Switch to \(page.rawValue) (\u{2318}\(page.commandShortcut))")
        .onHover { hovered in
            isHovered = hovered
        }
    }

    private var buttonBackground: Color {
        isSelected
            ? Color(nsColor: theme.settingsSelectedFill)
            : isHovered
                ? Color(nsColor: theme.settingsInteractiveHoverFill)
                : Color.clear
    }

    private var buttonBorderColor: Color {
        isSelected
            ? Color(nsColor: theme.settingsSelectedBorderColor)
            : isHovered
                ? Color(nsColor: theme.settingsSidebarBorderColor).opacity(0.72)
                : Color.clear
    }

    private var iconBackground: Color {
        isSelected
            ? Color(nsColor: theme.settingsTint).opacity(theme.preferredColorScheme == .dark ? 0.22 : 0.12)
            : isHovered
                ? Color(nsColor: theme.settingsInteractivePressedFill)
                : Color(nsColor: theme.settingsChromeSurfaceColor)
    }

    private var iconBorderColor: Color {
        isSelected
            ? Color(nsColor: theme.settingsTint).opacity(0.18)
            : Color(nsColor: theme.settingsSidebarBorderColor).opacity(0.84)
    }

    private var iconForegroundColor: Color {
        isSelected
            ? Color(nsColor: theme.settingsTint)
            : Color(nsColor: theme.settingsSecondaryTextColor)
    }

    private var titleColor: Color {
        isSelected
            ? Color(nsColor: theme.settingsPrimaryTextColor)
            : isHovered
                ? Color(nsColor: theme.settingsPrimaryTextColor).opacity(0.92)
                : Color(nsColor: theme.settingsSecondaryTextColor)
    }

    private var shadowColor: Color {
        Color.black.opacity(theme.preferredColorScheme == .dark ? 0.18 : 0.08)
    }

    private var accentColor: Color {
        Color(nsColor: theme.settingsTint)
    }
}

struct SettingsSidebarFooter: View {
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CURRENT LOOK")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(Color(nsColor: theme.settingsSecondaryTextColor).opacity(0.76))

            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(Color(nsColor: theme.settingsTint))
                    .frame(width: 26, height: 8)
                Text(theme.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(nsColor: theme.settingsPrimaryTextColor))
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: theme.settingsChromeSurfaceColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(nsColor: theme.settingsSidebarBorderColor), lineWidth: 1)
                )
        )
    }
}

struct SettingsPageHeader: View {
    let page: SettingsPage
    let statusText: String?
    @Environment(\.heyBarTheme) private var theme

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Text(page.rawValue)
                .font(Font(theme.settingsPageTitleFont))
                .foregroundStyle(Color(nsColor: theme.settingsPrimaryTextColor))

            Spacer(minLength: 12)

            if let statusText {
                Text(statusText.uppercased())
                    .font(Font(theme.settingsLabelFont))
                    .tracking(1.2)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color(nsColor: theme.settingsAccentSoftFill))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color(nsColor: theme.settingsTint).opacity(0.14), lineWidth: 1)
                    )
                    .foregroundStyle(Color(nsColor: theme.settingsTint))
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 2)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SettingsGroupHeader: View {
    let title: String
    let detail: String?
    @Environment(\.heyBarTheme) private var theme

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title)
                .font(Font(theme.settingsLabelFont))
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(Color(nsColor: theme.settingsPrimaryTextColor).opacity(0.84))

            if let detail {
                Text(detail)
                    .font(Font(theme.settingsBodyFont))
                    .foregroundStyle(Color(nsColor: theme.settingsSecondaryTextColor).opacity(0.8))
            }

            Rectangle()
                .fill(Color(nsColor: theme.settingsSeparatorColor))
                .frame(height: 1)
        }
        .padding(.top, 6)
    }
}

enum SettingsCardTone {
    case positive
    case neutral
    case attention
    case inactive

    func fillColor(theme: AppTheme) -> Color {
        switch self {
        case .positive:
            return Color(nsColor: theme.settingsTint).opacity(theme.preferredColorScheme == .dark ? 0.28 : 0.16)
        case .neutral:
            return Color(nsColor: theme.settingsChromeSurfaceColor)
        case .attention:
            return Color(nsColor: theme.closeTint).opacity(theme.preferredColorScheme == .dark ? 0.22 : 0.16)
        case .inactive:
            return Color(nsColor: theme.settingsChromeSurfaceColor).opacity(theme.preferredColorScheme == .dark ? 0.82 : 1)
        }
    }

    func textColor(theme: AppTheme) -> Color {
        switch self {
        case .positive:
            return Color(nsColor: theme.settingsTint)
        case .neutral:
            return Color(nsColor: theme.settingsPrimaryTextColor).opacity(0.78)
        case .attention:
            return Color(nsColor: theme.closeTint)
        case .inactive:
            return Color(nsColor: theme.settingsSecondaryTextColor).opacity(0.82)
        }
    }

    func surfaceColor(theme: AppTheme) -> Color {
        switch self {
        case .positive:
            return fillColor(theme: theme).opacity(theme.preferredColorScheme == .dark ? 0.52 : 0.84)
        case .neutral:
            return Color(nsColor: theme.settingsSectionSurfaceColor)
        case .attention:
            return fillColor(theme: theme).opacity(theme.preferredColorScheme == .dark ? 0.48 : 0.82)
        case .inactive:
            return Color(nsColor: theme.settingsSectionSurfaceColor).opacity(theme.preferredColorScheme == .dark ? 0.9 : 1)
        }
    }

    func borderColor(theme: AppTheme) -> Color {
        switch self {
        case .positive, .attention:
            return textColor(theme: theme).opacity(0.18)
        case .neutral:
            return Color(nsColor: theme.panelBorder).opacity(0.12)
        case .inactive:
            return Color(nsColor: theme.panelBorder).opacity(0.08)
        }
    }
}

struct SettingsPageScroll<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SettingsLayout.sectionSpacing) {
                content
            }
            .padding(SettingsLayout.contentPadding)
        }
    }
}

struct SettingsCardGrid<Content: View>: View {
    @ViewBuilder var content: Content

    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 460), spacing: 16, alignment: .top)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
            content
        }
    }
}

struct SettingsSectionCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let statusText: String?
    let tone: SettingsCardTone
    let iconName: String?
    @Environment(\.heyBarTheme) private var theme
    @State private var isHovered = false
    @ViewBuilder var content: Content

    init(
        title: String,
        subtitle: String? = nil,
        statusText: String? = nil,
        tone: SettingsCardTone = .neutral,
        iconName: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.statusText = statusText
        self.tone = tone
        self.iconName = iconName
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SettingsLayout.cardSpacing) {
            HStack(alignment: .top, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    if let iconName {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(tone.fillColor(theme: theme).opacity(theme.preferredColorScheme == .dark ? 0.72 : 1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(tone.textColor(theme: theme).opacity(0.14), lineWidth: 1)
                                )
                            Image(systemName: iconName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(tone.textColor(theme: theme))
                        }
                        .frame(width: 30, height: 30)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .font(Font(theme.settingsSectionTitleFont))
                            .foregroundStyle(Color(nsColor: theme.settingsPrimaryTextColor))

                        if let subtitle {
                            Text(subtitle)
                                .font(Font(theme.settingsBodyFont))
                                .foregroundStyle(Color(nsColor: theme.settingsSecondaryTextColor))
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                Spacer(minLength: 10)

                if let statusText {
                    Text(statusText.uppercased())
                        .font(Font(theme.settingsLabelFont))
                        .tracking(1.1)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(
                            Capsule(style: .continuous)
                                .fill(tone.fillColor(theme: theme))
                        )
                        .foregroundStyle(tone.textColor(theme: theme))
                }
            }

            Rectangle()
                .fill(Color(nsColor: theme.settingsSeparatorColor))
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 12) {
                content
            }
        }
        .padding(SettingsLayout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(cardSurfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(cardBorderColor, lineWidth: 1)
                )
        )
        .onHover { hovered in
            isHovered = hovered
        }
    }

    private var cardSurfaceColor: Color {
        isHovered ? tone.surfaceColor(theme: theme).opacity(theme.preferredColorScheme == .dark ? 0.96 : 1) : tone.surfaceColor(theme: theme)
    }

    private var cardBorderColor: Color {
        isHovered
            ? Color(nsColor: theme.settingsSelectedBorderColor).opacity(0.72)
            : tone.borderColor(theme: theme)
    }
}

struct SettingsInfoPill: View {
    let text: String
    @Environment(\.heyBarTheme) private var theme

    var body: some View {
        Text(text)
            .font(Font(theme.settingsPillFont))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(Color(nsColor: theme.settingsChromeSurfaceColor))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color(nsColor: theme.settingsSidebarBorderColor).opacity(0.9), lineWidth: 1)
            )
            .foregroundStyle(Color(nsColor: theme.settingsTint))
    }
}

struct SettingsSecondaryButtonStyle: ButtonStyle {
    @Environment(\.heyBarTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Font(theme.settingsBodyFont))
            .foregroundStyle(Color(nsColor: theme.settingsPrimaryTextColor))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: configuration.isPressed ? theme.settingsInteractivePressedFill : theme.settingsChromeSurfaceColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color(nsColor: theme.settingsSidebarBorderColor), lineWidth: 1)
                    )
                    .opacity(configuration.isPressed ? 0.82 : 1)
            )
    }
}

struct SettingsPrimaryButtonStyle: ButtonStyle {
    @Environment(\.heyBarTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Font(theme.settingsBodyFont))
            .foregroundStyle(Color(nsColor: theme.preferredColorScheme == .dark ? ThemeCatalog.hex(0x08100D) : .white))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: configuration.isPressed ? theme.settingsTint.withAlphaComponent(0.78) : theme.settingsTint))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color(nsColor: theme.settingsTint).opacity(0.16), lineWidth: 1)
                    )
            )
    }
}

struct SettingsActionRow<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 10) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SettingsMiniValueRow: View {
    let title: String
    let value: String
    @Environment(\.heyBarTheme) private var theme

    var body: some View {
        HStack {
            Text(title)
                .font(Font(theme.settingsBodyFont))
                .foregroundStyle(Color(nsColor: theme.settingsSecondaryTextColor))
            Spacer(minLength: 12)
            Text(value)
                .font(Font(theme.settingsBodyFont).weight(.bold))
                .foregroundStyle(Color(nsColor: theme.settingsPrimaryTextColor))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: theme.settingsChromeSurfaceColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(nsColor: theme.settingsSidebarBorderColor).opacity(0.9), lineWidth: 1)
                )
        )
    }
}

struct SettingsInlineMessage: View {
    let text: String
    let isError: Bool
    @Environment(\.heyBarTheme) private var theme

    var body: some View {
        Text(text)
            .font(Font(theme.settingsBodyFont))
            .foregroundStyle(
                isError
                    ? Color(nsColor: theme.settingsErrorTextColor)
                    : Color(nsColor: theme.settingsSecondaryTextColor)
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        isError
                            ? Color(nsColor: theme.settingsErrorTextColor).opacity(0.08)
                            : Color(nsColor: theme.settingsChromeSurfaceColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                isError
                                    ? Color(nsColor: theme.settingsErrorTextColor).opacity(0.18)
                                    : Color(nsColor: theme.settingsSidebarBorderColor).opacity(0.9),
                                lineWidth: 1
                            )
                    )
            )
    }
}

struct SettingsHelpStateCard: View {
    let title: String
    let message: String
    let iconName: String
    let tone: SettingsCardTone
    var tips: [String] = []
    @Environment(\.heyBarTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tone.fillColor(theme: theme))
                    Image(systemName: iconName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(tone.textColor(theme: theme))
                }
                .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Font(theme.settingsSectionTitleFont))
                        .foregroundStyle(Color(nsColor: theme.settingsPrimaryTextColor))
                    Text(message)
                        .font(Font(theme.settingsBodyFont))
                        .foregroundStyle(Color(nsColor: theme.settingsSecondaryTextColor))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !tips.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Color(nsColor: theme.settingsTint))
                                .frame(width: 6, height: 6)
                                .padding(.top, 5)
                            Text(tip)
                                .font(Font(theme.settingsBodyFont))
                                .foregroundStyle(Color(nsColor: theme.settingsPrimaryTextColor))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(SettingsLayout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(tone.surfaceColor(theme: theme))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(tone.borderColor(theme: theme), lineWidth: 1)
                )
        )
    }
}

struct ThemePreviewCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(theme.swiftUIPanelGradient)
                        .frame(height: SettingsLayout.themeCardHeight)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: theme.symbolName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(nsColor: theme.titleColor))
                                .frame(width: 32, height: 32)
                                .background(Color(nsColor: theme.closeFill))
                                .clipShape(Circle())

                            Spacer()

                            Text(isSelected ? "ACTIVE" : "PREVIEW")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(nsColor: theme.settingsFill))
                                .foregroundStyle(Color(nsColor: theme.settingsTint))
                                .clipShape(Capsule())
                        }

                        Text(theme.name)
                            .font(font(theme.titleFontName, size: 17, fallback: .system(size: 17, weight: .bold)))
                            .foregroundStyle(Color(nsColor: theme.titleColor))

                        Text(theme.fontPairLabel)
                            .font(font(theme.cardFontName, size: 10.5, fallback: .system(size: 10.5, weight: .semibold)))
                            .foregroundStyle(Color(nsColor: theme.bodyColor).opacity(0.92))

                        HStack(spacing: 10) {
                            ThemeMiniTile(theme: theme, title: "Keep Awake")
                            ThemeMiniTile(theme: theme, title: "Key Light", alternate: true)
                        }

                        ThemeSurfaceStrip(theme: theme)
                    }
                    .padding(14)
                }

                HStack {
                    Text(isSelected ? "Selected for app" : "Apply to app")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(nsColor: theme.settingsTint))

                    Spacer(minLength: 8)

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "arrow.right.circle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(nsColor: theme.settingsTint))
                }
                .padding(.horizontal, 2)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(nsColor: cardFillColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                isSelected
                                    ? Color(nsColor: theme.settingsTint).opacity(0.32)
                                    : Color(nsColor: isHovered ? theme.settingsSelectedBorderColor : theme.settingsSidebarBorderColor).opacity(isHovered ? 0.92 : 0.75),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovered in
            isHovered = hovered
        }
    }

    private var cardFillColor: NSColor {
        if isSelected {
            return theme.settingsSelectedFill
        }
        if isHovered {
            return theme.settingsInteractiveHoverFill
        }
        return theme.settingsSectionSurfaceColor
    }

    private func font(_ name: String, size: CGFloat, fallback: Font) -> Font {
        if let custom = NSFont(name: name, size: size) {
            return Font(custom)
        }
        return fallback
    }
}

struct ThemeSurfaceStrip: View {
    let theme: AppTheme

    var body: some View {
        HStack(spacing: 8) {
            ThemeSurfaceDot(label: "Accent", color: Color(nsColor: theme.settingsTint))
            ThemeSurfaceDot(label: "Shell", color: Color(nsColor: theme.settingsFill))
            ThemeSurfaceDot(label: "Panel", color: Color(nsColor: theme.closeFill))
        }
    }
}

struct ThemeSurfaceDot: View {
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.14))
        .clipShape(Capsule())
    }
}

struct ThemeMiniTile: View {
    let theme: AppTheme
    let title: String
    var alternate = false

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(
                LinearGradient(
                    colors: (alternate ? theme.tileSecondaryGradient : theme.tileGradient).map(Color.init(nsColor:)),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(alignment: .topTrailing) {
                Text("ON")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(nsColor: theme.badgeOnFill))
                    .foregroundStyle(Color(nsColor: theme.badgeOnText))
                    .clipShape(Capsule())
                    .padding(10)
            }
            .overlay(alignment: .bottomLeading) {
                Text(title)
                    .font(font(theme.cardFontName, size: 11, fallback: .system(size: 11, weight: .bold)))
                    .foregroundStyle(Color(nsColor: theme.tileForegroundColor(alternate: alternate)))
                    .padding(10)
            }
            .frame(height: 72)
    }

    private func font(_ name: String, size: CGFloat, fallback: Font) -> Font {
        if let custom = NSFont(name: name, size: size) {
            return Font(custom)
        }
        return fallback
    }
}
