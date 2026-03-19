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

            SettingsSectionCard(
                title: "Shortcut Matrix",
                subtitle: "Global commands for HeyBar actions. Record a combination, then clear or replace it at any time.",
                statusText: "\(configuredShortcutCount) Active",
                tone: configuredShortcutCount == 0 ? .attention : .positive,
                iconName: "command.square"
            ) {
                HStack(spacing: 10) {
                    SettingsInfoPill(text: "Global")
                    SettingsInfoPill(text: "Conflict Aware")
                    SettingsInfoPill(text: "Editable")
                }

                SettingsInlineMessage(text: "Click a recorder, then press the key combination you want to use.", isError: false)

                if let lastError = controller.lastError {
                    SettingsInlineMessage(text: lastError, isError: true)
                }
            }

            ShortcutSettingsSection(
                title: "Session",
                detail: "Primary control",
                actions: [.keepAwake],
                controller: controller
            )

            ShortcutSettingsSection(
                title: "Cleaning",
                detail: "Input lock mode",
                actions: [.cleanKey],
                controller: controller
            )

            ShortcutSettingsSection(
                title: "Finder",
                detail: "Visibility tools",
                actions: [.showHiddenFiles, .showFileExtensions],
                controller: controller
            )

            ShortcutSettingsSection(
                title: "Display",
                detail: "Screen and keyboard lighting",
                actions: [.nightShift, .keyLight],
                controller: controller
            )

            ShortcutSettingsSection(
                title: "Automation",
                detail: "Dock and menu bar actions",
                actions: [.hideDock, .hideBar],
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

struct ShortcutSettingsSection: View {
    let title: String
    let detail: String
    let actions: [ShortcutAction]
    @ObservedObject var controller: ShortcutController
    @Environment(\.heyBarTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsGroupHeader(title: title, detail: detail)

            ForEach(actions) { action in
                SettingsSectionCard(
                    title: action.title,
                    subtitle: action.categoryLabel,
                    statusText: controller.shortcut(for: action) == nil ? "Unset" : "Ready",
                    tone: controller.shortcut(for: action) == nil ? .neutral : .positive,
                    iconName: action.iconName
                ) {
                    HStack(alignment: .center, spacing: 12) {
                        if let shortcut = controller.shortcut(for: action) {
                            SettingsInfoPill(text: shortcut.displayString)
                        } else {
                            SettingsInfoPill(text: "No Shortcut")
                        }

                        Spacer(minLength: 12)

                        ShortcutRecorderField(shortcut: Binding(
                            get: { controller.shortcut(for: action) },
                            set: { controller.setShortcut($0, for: action) }
                        ))
                        .frame(width: SettingsLayout.shortcutRecorderWidth, height: SettingsLayout.shortcutRecorderHeight)

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
