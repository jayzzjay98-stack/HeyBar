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

    var body: some View {
        SettingsPageScroll {
            SettingsPageHeader(page: .preferences, statusText: launchAtLogin ? "Enabled" : "Disabled")

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
