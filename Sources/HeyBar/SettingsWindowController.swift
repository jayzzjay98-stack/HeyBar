import AppKit
import SwiftUI

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
    static let sidebarWidth: CGFloat = 236
    static let contentCornerRadius: CGFloat = 28
    static let sidebarCornerRadius: CGFloat = 24
    static let cardPadding: CGFloat = 18
    static let cardSpacing: CGFloat = 16
    static let sectionSpacing: CGFloat = 18
    static let sidebarBlockPadding: CGFloat = 10
    static let sidebarItemSpacing: CGFloat = 10
    static let sidebarRowHorizontalPadding: CGFloat = 11
    static let sidebarRowVerticalPadding: CGFloat = 9
    // Radii for the background gradient orbs in SettingsWindowBackground
    static let backgroundTintOrbRadius: CGFloat = 260
    static let backgroundCloseOrbRadius: CGFloat = 240
    // General sidebar width used in GeneralSettingsPage feature list
    static let generalSidebarWidth: CGFloat = 300
    // Animation durations
    static let selectionDuration: TimeInterval = 0.12
    static let themeChangeDuration: TimeInterval = 0.16
}

@MainActor
final class SettingsWindowController: NSWindowController {
    private let model: AppModel
    private let hostingController: NSHostingController<SettingsView>
    var onWindowClose: (() -> Void)?
    private var cmdWMonitor: Any?

    init(model: AppModel) {
        self.model = model
        let contentView = SettingsView(model: model)
        hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: SettingsLayout.windowSize),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "HeyBar Studio"
        window.contentViewController = hostingController
        window.center()
        window.isReleasedWhenClosed = false
        window.isRestorable = false
        window.animationBehavior = .none
        window.hidesOnDeactivate = false

        super.init(window: window)

        // ⌘W closes the Settings window (HIG standard)
        cmdWMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.modifierFlags.contains(.command),
                  event.charactersIgnoringModifiers == "w" else { return event }
            self?.window?.performClose(nil)
            return nil
        }

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                if let monitor = self?.cmdWMonitor {
                    NSEvent.removeMonitor(monitor)
                    self?.cmdWMonitor = nil
                }
                self?.onWindowClose?()
            }
        }

    }

    deinit { }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Renders the window invisibly so the first `present()` is instant.
    func preWarm() {
        guard let window else { return }
        window.alphaValue = 0
        centerWindowOnActiveScreen(window)
        window.orderFront(nil)
    }

    func present() {
        guard let window else { return }
        // Re-install ⌘W monitor if it was removed when the window last closed.
        if cmdWMonitor == nil {
            cmdWMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard event.modifierFlags.contains(.command),
                      event.charactersIgnoringModifiers == "w" else { return event }
                self?.window?.performClose(nil)
                return nil
            }
        }
        if window.isMiniaturized {
            window.deminiaturize(nil)
            return
        }

        if window.isVisible {
            if window.alphaValue > 0 {
                // Already fully visible — just bring to front.
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            } else {
                // Pre-warmed: SwiftUI has already rendered invisibly, reveal instantly.
                centerWindowOnActiveScreen(window)
                window.alphaValue = 1
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            return
        }

        // Cold start without pre-warm: hide while SwiftUI renders, then reveal.
        window.alphaValue = 0
        centerWindowOnActiveScreen(window)
        window.orderFront(nil)
        DispatchQueue.main.async { [weak self] in
            guard let window = self?.window else { return }
            self?.centerWindowOnActiveScreen(window)
            window.alphaValue = 1
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func centerWindowOnActiveScreen(_ window: NSWindow) {
        let mouseLocation = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) ?? NSScreen.main
        let visibleFrame = targetScreen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? window.screen?.visibleFrame ?? NSRect(origin: .zero, size: SettingsLayout.windowSize)

        var frame = window.frame
        frame.size.width = min(frame.size.width, visibleFrame.width)
        frame.size.height = min(frame.size.height, visibleFrame.height)
        frame.origin.x = visibleFrame.midX - frame.size.width / 2
        frame.origin.y = visibleFrame.midY - frame.size.height / 2

        frame.origin.x = max(visibleFrame.minX, min(frame.origin.x, visibleFrame.maxX - frame.size.width))
        frame.origin.y = max(visibleFrame.minY, min(frame.origin.y, visibleFrame.maxY - frame.size.height))

        window.setFrame(frame, display: true)
    }
}

struct SettingsView: View {
    @ObservedObject var model: AppModel

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
        // ⌘, navigates to Preferences tab (HIG standard shortcut)
        .background(
            Button("") { model.selectedPage = .preferences }
                .keyboardShortcut(",", modifiers: .command)
                .hidden()
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
            GeneralSettingsPage(onQuit: model.onQuit)
        case .preferences:
            PreferencesSettingsPage()
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

