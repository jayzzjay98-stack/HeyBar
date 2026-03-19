import AppKit
import SwiftUI
import ServiceManagement

enum SettingsLayout {
    static let windowSize = NSSize(width: 1004, height: 700)
    static let minimumWindowSize = NSSize(width: 960, height: 660)
    static let detailPadding: CGFloat = 16
    static let themeCardHeight: CGFloat = 180
    static let themeGridMinimum: CGFloat = 210
    static let themeGridMaximum: CGFloat = 240
    static let contentPadding: CGFloat = 24
    static let shortcutRecorderWidth: CGFloat = 150
    static let shortcutRecorderHeight: CGFloat = 30
    static let settingsMetricWidth: CGFloat = 42
    static let shellInset: CGFloat = 18
    static let shellSpacing: CGFloat = 16
    static let sidebarWidth: CGFloat = 215
    static let contentCornerRadius: CGFloat = 28
    static let sidebarCornerRadius: CGFloat = 24
    static let cardPadding: CGFloat = 18
    static let cardSpacing: CGFloat = 16
    static let sectionSpacing: CGFloat = 18
    static let sidebarBlockPadding: CGFloat = 10
    static let sidebarItemSpacing: CGFloat = 10
    static let sidebarRowHorizontalPadding: CGFloat = 11
    static let sidebarRowVerticalPadding: CGFloat = 9
}

@MainActor
final class SettingsWindowController: NSWindowController {
    private let model: AppModel
    private let hostingController: NSHostingController<SettingsView>

    init(model: AppModel) {
        self.model = model
        let contentView = SettingsView(model: model)
        hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: SettingsLayout.windowSize),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.title = "HeyBar Studio"
        window.contentViewController = hostingController
        window.center()
        window.isReleasedWhenClosed = false
        // Keep the window visible when the user switches to another app.
        // LSUIElement apps have no Dock presence, so the default hide-on-deactivate
        // behaviour causes the settings window to vanish unexpectedly.
        window.hidesOnDeactivate = false

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present() {
        guard let window else { return }
        hostingController.rootView = SettingsView(model: model)
        if window.isMiniaturized {
            window.deminiaturize(nil)
        }
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }
}

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled
    @State private var launchAtLoginError: String?

    var body: some View {
        let theme = model.selectedTheme

        ZStack {
            SettingsWindowBackground(theme: theme)
                .ignoresSafeArea()

            HStack(spacing: SettingsLayout.shellSpacing) {
                SettingsSidebar(theme: theme) {
                    settingsSidebar
                }

                SettingsDetailSurface(theme: theme) {
                    SettingsContentCard(theme: theme) {
                        settingsDetail
                    }
                    .padding(SettingsLayout.shellInset)
                }
            }
        }
        .tint(Color(nsColor: theme.settingsTint))
        .preferredColorScheme(theme.preferredColorScheme)
        .environment(\.heyBarTheme, theme)
        .environmentObject(model)
        .frame(
            minWidth: SettingsLayout.minimumWindowSize.width,
            minHeight: SettingsLayout.minimumWindowSize.height
        )
    }

    private var settingsSidebar: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsBrandLockup(theme: model.selectedTheme)

            VStack(alignment: .leading, spacing: SettingsLayout.sidebarItemSpacing) {
                ForEach(SettingsPage.allCases) { page in
                    SettingsSidebarButton(
                        theme: model.selectedTheme,
                        page: page,
                        isSelected: model.selectedPage == page
                    ) {
                        model.selectedPage = page
                    }
                }
            }
            .padding(SettingsLayout.sidebarBlockPadding)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(nsColor: model.selectedTheme.settingsChromeSurfaceColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color(nsColor: model.selectedTheme.settingsSidebarBorderColor).opacity(0.8), lineWidth: 1)
                    )
            )

            Spacer(minLength: 0)

            SettingsSidebarFooter(theme: model.selectedTheme)
        }
    }

    @ViewBuilder
    private var settingsDetail: some View {
        switch model.selectedPage ?? .general {
        case .general:
            GeneralSettingsPage(
                launchAtLogin: $launchAtLogin,
                launchAtLoginError: $launchAtLoginError,
                onQuit: model.onQuit
            )
        case .themes:
            ThemesSettingsPage()
        case .shortcuts:
            ShortcutSettingsPage(controller: model.shortcuts)
        case .about:
            AboutSettingsPage(updater: model.updater)
        }
    }

}

private struct HeyBarThemeKey: EnvironmentKey {
    static let defaultValue = ThemeCatalog.fallbackTheme
}

extension EnvironmentValues {
    var heyBarTheme: AppTheme {
        get { self[HeyBarThemeKey.self] }
        set { self[HeyBarThemeKey.self] = newValue }
    }
}

extension View {
    func themeSecondary(_ theme: AppTheme) -> some View {
        foregroundStyle(Color(nsColor: theme.settingsSecondaryTextColor))
    }

    func themeError(_ theme: AppTheme) -> some View {
        foregroundStyle(Color(nsColor: theme.settingsErrorTextColor))
    }
}
