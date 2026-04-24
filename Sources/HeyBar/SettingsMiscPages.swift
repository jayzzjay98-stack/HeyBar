import AppKit
import SwiftUI
import ServiceManagement

private enum AppInfo {
    static let version: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }()
    static let build: String = {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }()
    static let versionLabel = "v\(version)"
    static let buildLabel = "Build \(build)"
    static let versionDetail = "Version \(version)"
}

// MARK: - Preferences Page

struct PreferencesSettingsPage: View {
    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled
    @State private var launchAtLoginError: String?
    @State private var menuBarIconStyle = MenuBarIconStyleStore().load()
    @State private var iconChooserExpanded = false
    private let iconStyleStore = MenuBarIconStyleStore()

    var body: some View {
        SettingsPageScroll {
            SettingsPageHeader(page: .preferences, statusText: launchAtLogin ? "Enabled" : "Disabled")

            SettingsSectionCard(
                title: "Menu Bar Icon",
                subtitle: "Choose the HeyBar icon that sits in the macOS menu bar.",
                statusText: menuBarIconStyle.title,
                tone: .neutral,
                iconName: "menubar.rectangle"
            ) {
                MenuBarIconStylePicker(
                    selection: menuBarIconStyle,
                    isExpanded: iconChooserExpanded
                ) { style in
                    menuBarIconStyle = style
                    iconStyleStore.save(style)
                } onToggleExpanded: {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        iconChooserExpanded.toggle()
                    }
                }
            }

            // MARK: Launch at Login
            SettingsSectionCard(
                title: "Launch at Login",
                subtitle: "Make HeyBar available as soon as your Mac session starts.",
                statusText: launchAtLogin ? "Enabled" : "Disabled",
                tone: launchAtLogin ? .positive : .neutral,
                iconName: "power.circle"
            ) {
                Toggle(isOn: Binding(
                    get: { launchAtLogin },
                    set: { applyLaunchAtLogin($0) }
                )) {
                    Label("Launch at Login", systemImage: "power.circle")
                }
                .toggleStyle(.switch)

                if let error = launchAtLoginError {
                    SettingsInlineMessage(text: error, isError: true)
                }
            }
        }
        .navigationTitle("Preferences")
    }

    private func applyLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else       { try SMAppService.mainApp.unregister() }
            launchAtLogin = enabled
            launchAtLoginError = nil
        } catch {
            launchAtLoginError = "Could not \(enabled ? "enable" : "disable") Launch at Login. \(error.localizedDescription)"
        }
    }
}

private struct MenuBarIconStylePicker: View {
    let selection: MenuBarIconStyle
    let isExpanded: Bool
    let onSelect: (MenuBarIconStyle) -> Void
    let onToggleExpanded: () -> Void
    @Environment(\.heyBarTheme) private var theme

    private let columns = [
        GridItem(.adaptive(minimum: 88, maximum: 88), spacing: 10, alignment: .top)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onToggleExpanded) {
                pickerLabel
            }
            .buttonStyle(.plain)
            .help("Choose the HeyBar menu bar icon")

            if isExpanded {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                    ForEach(MenuBarIconStyle.allCases) { style in
                        MenuBarIconStyleButton(
                            style: style,
                            isSelected: selection == style
                        ) {
                            onSelect(style)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var pickerLabel: some View {
        HStack(spacing: 12) {
            MenuBarIconPreview(style: selection, size: .large)

            VStack(alignment: .leading, spacing: 3) {
                Text(selection.title)
                    .font(Font(theme.settingsBodyFont).weight(.semibold))
                    .foregroundStyle(Color(nsColor: theme.settingsPrimaryTextColor))
                Text(isExpanded ? "Choose an icon below" : "Click once to show all icons")
                    .font(Font(theme.settingsBodyFont))
                    .foregroundStyle(Color(nsColor: theme.settingsSecondaryTextColor))
            }

            Spacer(minLength: 12)

            HStack(spacing: 12) {
                Text("\(MenuBarIconStyle.allCases.count)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(nsColor: theme.settingsSecondaryTextColor))
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(nsColor: theme.settingsSecondaryTextColor))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
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

private struct MenuBarIconStyleButton: View {
    let style: MenuBarIconStyle
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.heyBarTheme) private var theme
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(iconBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(iconBorderColor, lineWidth: 1)
                        )

                    iconPreview
                }
                .frame(width: 36, height: 26)

                Text(style.title)
                    .font(Font(theme.settingsBodyFont).weight(.semibold))
                    .foregroundStyle(titleColor)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .frame(width: 86)
            .frame(minHeight: 72)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .help("Use \(style.title) as the HeyBar menu bar icon")
        .accessibilityLabel(style.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .onHover { hovered in
            isHovered = hovered
        }
    }

    @ViewBuilder
    private var iconPreview: some View {
        MenuBarIconPreview(style: style, size: .compact, color: iconColor)
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color(nsColor: theme.settingsTint).opacity(theme.preferredColorScheme == .dark ? 0.18 : 0.1)
        }
        return isHovered
            ? Color(nsColor: theme.settingsInteractiveHoverFill)
            : Color(nsColor: theme.settingsChromeSurfaceColor)
    }

    private var borderColor: Color {
        isSelected
            ? Color(nsColor: theme.settingsTint).opacity(0.42)
            : Color(nsColor: theme.settingsSidebarBorderColor).opacity(isHovered ? 0.9 : 0.68)
    }

    private var iconBackground: Color {
        isSelected
            ? Color(nsColor: theme.settingsTint).opacity(theme.preferredColorScheme == .dark ? 0.22 : 0.13)
            : Color(nsColor: theme.settingsSectionSurfaceColor)
    }

    private var iconBorderColor: Color {
        isSelected
            ? Color(nsColor: theme.settingsTint).opacity(0.18)
            : Color(nsColor: theme.settingsSidebarBorderColor).opacity(0.7)
    }

    private var iconColor: Color {
        isSelected
            ? Color(nsColor: theme.settingsTint)
            : Color(nsColor: theme.settingsPrimaryTextColor).opacity(0.78)
    }

    private var titleColor: Color {
        isSelected
            ? Color(nsColor: theme.settingsPrimaryTextColor)
            : Color(nsColor: theme.settingsSecondaryTextColor)
    }
}

private struct MenuBarIconPreview: View {
    enum Size {
        case compact
        case large
    }

    let style: MenuBarIconStyle
    let size: Size
    var color: Color?
    @Environment(\.heyBarTheme) private var theme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: theme.settingsSectionSurfaceColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(nsColor: theme.settingsSidebarBorderColor).opacity(0.7), lineWidth: 1)
                )

            icon
        }
        .frame(width: frameWidth, height: frameHeight)
    }

    @ViewBuilder
    private var icon: some View {
        if style == .bar {
            Text("|")
                .font(.system(size: barPointSize, weight: .light))
                .foregroundStyle(foregroundColor)
        } else {
            Image(systemName: style.previewSymbolName)
                .font(.system(size: iconPointSize, weight: .regular))
                .foregroundStyle(foregroundColor)
        }
    }

    private var frameWidth: CGFloat {
        switch size {
        case .compact: return 36
        case .large:   return 40
        }
    }

    private var frameHeight: CGFloat {
        switch size {
        case .compact: return 26
        case .large:   return 30
        }
    }

    private var iconPointSize: CGFloat {
        switch size {
        case .compact: return 13
        case .large:   return 14
        }
    }

    private var barPointSize: CGFloat {
        switch size {
        case .compact: return 17
        case .large:   return 18
        }
    }

    private var foregroundColor: Color {
        color ?? Color(nsColor: theme.settingsTint)
    }
}

// MARK: - Themes Page

struct ThemesSettingsPage: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let columns = [
        GridItem(.flexible(), spacing: SettingsLayout.detailPadding),
        GridItem(.flexible(), spacing: SettingsLayout.detailPadding),
        GridItem(.flexible(), spacing: SettingsLayout.detailPadding)
    ]

    var body: some View {
        SettingsPageScroll {
            SettingsPageHeader(
                page: .themes,
                statusText: ThemeCatalog.theme(for: model.selectedThemeID).name
            )

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(ThemeCatalog.themes) { theme in
                    ThemePreviewCard(
                        theme: theme,
                        isSelected: model.selectedThemeID == theme.id
                    ) {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: SettingsLayout.themeChangeDuration)) {
                            model.selectedThemeID = theme.id
                        }
                    }
                }
            }
        }
        .navigationTitle("Themes")
    }
}

struct UnsupportedSettingsPage: View {
    @ObservedObject var controller: UnsupportedFeatureController
    @Environment(\.heyBarTheme) private var theme

    var body: some View {
        Form {
            Section(controller.title) {
                Text(controller.message)
                    .themeSecondary(theme)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(controller.title)
    }
}

struct AboutSettingsPage: View {
    @ObservedObject var updater: InAppUpdater
    @Environment(\.heyBarTheme) private var theme

    var body: some View {
        SettingsPageScroll {
            SettingsPageHeader(
                page: .about,
                statusText: AppInfo.versionLabel
            )

            SettingsSectionCard(
                title: "Software Update",
                subtitle: updateSubtitle,
                statusText: AppInfo.versionLabel,
                tone: .neutral,
                iconName: "arrow.clockwise"
            ) {
                updateControls
            }

            SettingsSectionCard(
                title: "HeyBar is free",
                subtitle: "No subscription, no trial, no catch.",
                statusText: "Free",
                tone: .neutral,
                iconName: "heart"
            ) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("I built HeyBar because I kept reaching for the same macOS settings every day and wanted them one click away. It's free and open source — use it however you like.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(nsColor: theme.settingsPrimaryTextColor).opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)

                    Text("If HeyBar saves you a few clicks a day and you'd like to buy me a coffee, I'd genuinely appreciate it. No pressure at all.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(nsColor: theme.settingsPrimaryTextColor).opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        if let url = URL(string: "https://github.com/jayzzjay98-stack/HeyBar") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Label("Support on GitHub", systemImage: "cup.and.saucer.fill")
                    }
                    .buttonStyle(SettingsSecondaryButtonStyle())
                }
            }
        }
        .navigationTitle("About")
    }

    private var updateSubtitle: String {
        switch updater.state {
        case .idle:
            return "You're on \(AppInfo.versionLabel). Check if a newer version is available."
        case .checking:
            return "Checking for updates…"
        case .upToDate:
            return "You're on \(AppInfo.versionLabel) — that's the latest."
        case .available(let version, _):
            return "Version \(version) is available."
        case .downloading:
            return "Downloading update…"
        case .downloaded(let version, _):
            return "Version \(version) is ready to install."
        case .installing:
            return "Installing… HeyBar will relaunch shortly."
        case .failed(let message):
            return message
        }
    }

    @ViewBuilder
    private var updateControls: some View {
        switch updater.state {
        case .idle, .failed:
            Button {
                updater.checkForUpdates()
            } label: {
                Label("Check for Updates", systemImage: "arrow.clockwise")
            }
            .buttonStyle(SettingsSecondaryButtonStyle())

        case .checking:
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Checking…")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(nsColor: theme.settingsSecondaryTextColor))
            }

        case .upToDate:
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.green)
                    Text("You're up to date.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(nsColor: theme.settingsSecondaryTextColor))
                }
                Spacer()
                Button {
                    updater.resetToIdle()
                } label: {
                    Text("Check Again")
                }
                .buttonStyle(SettingsSecondaryButtonStyle())
            }

        case .available(let version, let downloadURL):
            VStack(alignment: .leading, spacing: 10) {
                Text("Version \(version) is available.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(nsColor: theme.settingsPrimaryTextColor))
                Button {
                    updater.startDownload(version: version, downloadURL: downloadURL)
                } label: {
                    Label("Download Update", systemImage: "arrow.down.circle")
                }
                .buttonStyle(SettingsPrimaryButtonStyle())
            }

        case .downloading:
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Downloading…")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(nsColor: theme.settingsSecondaryTextColor))
            }

        case .downloaded(let version, let zipURL):
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.green)
                    Text("Version \(version) downloaded.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(nsColor: theme.settingsPrimaryTextColor))
                }
                Button {
                    updater.installDownloaded(version: version, zipURL: zipURL)
                } label: {
                    Label("Install & Relaunch", systemImage: "arrow.clockwise.circle.fill")
                }
                .buttonStyle(SettingsPrimaryButtonStyle())
            }

        case .installing:
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Installing…")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(nsColor: theme.settingsSecondaryTextColor))
            }
        }
    }
}
