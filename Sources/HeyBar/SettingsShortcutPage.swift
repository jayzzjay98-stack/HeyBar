import SwiftUI

struct ShortcutSettingsPage: View {
    @ObservedObject var controller: ShortcutController
    @Environment(\.heyBarTheme) private var theme

    var body: some View {
        SettingsPageScroll {
            SettingsPageHeader(
                page: .shortcuts,
                statusText: configuredShortcutCount == 0 ? "Setup" : "\(configuredShortcutCount) Ready"
            )

            if configuredShortcutCount == 0 {
                SettingsHelpStateCard(
                    title: "No shortcuts yet",
                    message: "Set up a few global commands to make HeyBar feel instant.",
                    iconName: "command",
                    tone: .attention,
                    tips: [
                        "Start with Keep Awake so you always have one primary shortcut ready.",
                        "Add CleanKey if you want a fast cleaning lock without opening Quick Controls.",
                        "Use Finder shortcuts next if you often toggle hidden files or extensions.",
                        "Click any recorder, then press the key combination you want to use."
                    ]
                )
            }

            if let lastError = controller.lastError {
                SettingsInlineMessage(text: lastError, isError: true)
            }

            ShortcutGrid(
                actions: ShortcutAction.allCases,
                controller: controller
            )
        }
        .navigationTitle("Shortcuts")
        .foregroundStyle(Color(nsColor: theme.settingsPrimaryTextColor))
    }

    private var configuredShortcutCount: Int {
        ShortcutAction.allCases.reduce(0) { partialResult, action in
            partialResult + (controller.shortcut(for: action) == nil ? 0 : 1)
        }
    }
}

struct ShortcutGrid: View {
    let actions: [ShortcutAction]
    @ObservedObject var controller: ShortcutController

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(actions) { action in
                SettingsSectionCard(
                    title: action.title,
                    subtitle: action.categoryLabel,
                    tone: controller.shortcut(for: action) == nil ? .neutral : .positive,
                    iconName: action.iconName,
                    showSeparator: false
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        if let shortcut = controller.shortcut(for: action) {
                            SettingsInfoPill(text: shortcut.displayString)
                        } else {
                            SettingsInfoPill(text: "No Shortcut")
                        }

                        HStack(spacing: 8) {
                            ShortcutRecorderField(shortcut: Binding(
                                get: { controller.shortcut(for: action) },
                                set: { controller.setShortcut($0, for: action) }
                            ))
                            .frame(height: SettingsLayout.shortcutRecorderHeight)
                            .frame(maxWidth: .infinity)

                            Button("Clear") {
                                controller.setShortcut(nil, for: action)
                            }
                            .buttonStyle(SettingsSecondaryButtonStyle())
                        }
                    }
                }
            }
        }
    }
}

private extension ShortcutAction {
    var iconName: String {
        switch self {
        case .keepAwake:
            return "sparkles.tv"
        case .cleanKey:
            return "sparkles"
        case .showHiddenFiles:
            return "folder.badge.questionmark"
        case .showFileExtensions:
            return "doc.badge.gearshape"
        case .keyLight:
            return "keyboard"
        case .nightShift:
            return "moon.stars.fill"
        case .hideDock:
            return "dock.rectangle"
        case .hideBar:
            return "menubar.rectangle"
        }
    }

    var categoryLabel: String {
        switch self {
        case .keepAwake:
            return "Session Control"
        case .cleanKey:
            return "Cleaning Lock"
        case .showHiddenFiles, .showFileExtensions:
            return "Finder Tools"
        case .keyLight, .nightShift:
            return "Display Controls"
        case .hideDock, .hideBar:
            return "Automation"
        }
    }
}
