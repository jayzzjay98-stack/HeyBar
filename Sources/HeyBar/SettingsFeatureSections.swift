import SwiftUI

struct CleanKeySettingsSection: View {
    @ObservedObject var controller: CleanKeyController
    @Environment(\.heyBarTheme) private var theme

    private var durationBinding: Binding<Int> {
        Binding(
            get: { controller.durationMinutes },
            set: { controller.durationMinutes = $0 }
        )
    }

    private var soundBinding: Binding<Bool> {
        Binding(
            get: { controller.soundEnabled },
            set: { controller.soundEnabled = $0 }
        )
    }

    var body: some View {
        SettingsSectionCard(
            title: "CleanKey",
            subtitle: "Lock keyboard and mouse while you clean, then unlock automatically when the timer finishes.",
            statusText: controller.statusText,
            tone: controller.isCleaning ? .positive : (controller.hasAccessibilityPermission ? .neutral : .attention),
            iconName: "sparkles"
        ) {
            HStack {
                Text("Duration")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Picker("", selection: durationBinding) {
                    ForEach(controller.durationOptions, id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: 120)
            }

            Toggle("Play sounds while cleaning", isOn: soundBinding)
                .toggleStyle(.switch)

            if controller.isCleaning {
                SettingsMiniValueRow(title: "Remaining", value: controller.remainingBadgeText)
                SettingsMiniValueRow(title: "Unlock", value: "Press ESC 5 times")
            } else if !controller.hasAccessibilityPermission {
                SettingsHelpStateCard(
                    title: "Accessibility permission required",
                    message: "CleanKey mode needs Accessibility access before it can lock keyboard and mouse input.",
                    iconName: "figure.wave.circle",
                    tone: .attention,
                    tips: [
                        "Click Request Access to show the macOS permission prompt.",
                        "If the prompt does not appear, open Accessibility settings manually."
                    ]
                )
            } else {
                SettingsInlineMessage(text: "Start CleanKey mode from here or from Quick Controls. The overlay unlocks automatically when the timer ends.", isError: false)
            }

            if controller.isCleaning {
                SettingsActionRow {
                    Button { controller.stopCleaning() } label: {
                        Label("Stop CleanKey", systemImage: "lock.open.fill")
                    }
                    .buttonStyle(SettingsPrimaryButtonStyle())
                }
            } else if !controller.hasAccessibilityPermission {
                SettingsActionRow {
                    Button { controller.requestAccessibilityPermission() } label: {
                        Label("Request Access", systemImage: "hand.raised.fill")
                    }
                    .buttonStyle(SettingsPrimaryButtonStyle())

                    Button { controller.openAccessibilitySettings() } label: {
                        Label("Open Settings", systemImage: "gearshape")
                    }
                    .buttonStyle(SettingsSecondaryButtonStyle())
                }
            } else {
                SettingsActionRow {
                    Button { _ = controller.startCleaning() } label: {
                        Label("Start CleanKey", systemImage: "sparkles")
                    }
                    .buttonStyle(SettingsPrimaryButtonStyle())

                    Button { controller.openAccessibilitySettings() } label: {
                        Label("Open Settings", systemImage: "gearshape")
                    }
                    .buttonStyle(SettingsSecondaryButtonStyle())
                }
            }

            if let lastError = controller.lastError {
                SettingsInlineMessage(text: lastError, isError: true)
            }
        }
    }
}

struct KeepAwakeSettingsSection: View {
    @ObservedObject var controller: KeepAwakeController
    @Environment(\.heyBarTheme) private var theme

    private var currentMode: Int {
        if controller.scheduleEnabled { return 2 }
        if controller.usesDurationMode { return 1 }
        return 0
    }

    private var modeBinding: Binding<Int> {
        Binding(
            get: { currentMode },
            set: { newMode in
                switch newMode {
                case 0: controller.usesDurationMode = false; controller.scheduleEnabled = false
                case 1: controller.usesDurationMode = true; controller.scheduleEnabled = false
                case 2: controller.scheduleEnabled = true
                default: break
                }
            }
        )
    }

    var body: some View {
        SettingsSectionCard(
            title: "Keep Awake",
            subtitle: "Session timing, duration mode, and overnight schedule.",
            statusText: statusBadgeText,
            tone: controller.isEnabled ? .positive : .neutral,
            iconName: "sparkles.tv"
        ) {
            HStack {
                Text("Mode")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Picker("Mode", selection: modeBinding) {
                    Text("Manual").tag(0)
                    Text("Duration").tag(1)
                    Text("Schedule").tag(2)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 210)
            }

            if currentMode == 1 {
                HStack {
                    Text("Duration")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Picker("Duration", selection: $controller.durationMinutes) {
                        ForEach(controller.durationOptions, id: \.self) { d in
                            Text(controller.durationDescription(for: d)).tag(d)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 150)
                }
            }

            if currentMode == 2 {
                DatePicker("From", selection: $controller.startDate, displayedComponents: .hourAndMinute)
                DatePicker("To", selection: $controller.endDate, displayedComponents: .hourAndMinute)

                if controller.isTomorrow {
                    SettingsInlineMessage(text: "The end time rolls over to tomorrow.", isError: false)
                }
                SettingsInlineMessage(text: "Daily schedule takes priority while it is enabled.", isError: false)
            }
        }
    }

    private var statusBadgeText: String {
        guard controller.isEnabled else { return "Idle" }
        if controller.usesDurationMode, controller.durationMinutes > 0, !controller.scheduleEnabled,
           let expiry = controller.expiryDate {
            let remaining = expiry.timeIntervalSinceNow
            if remaining > 0 {
                let mins = Int(remaining / 60)
                let secs = Int(remaining) % 60
                return mins > 0 ? "\(mins)m left" : "\(secs)s left"
            }
        }
        return "Active"
    }
}

struct ShowHiddenFilesSettingsSection: View {
    @ObservedObject var controller: HiddenFilesController
    @Environment(\.heyBarTheme) private var theme

    private var visibilityBinding: Binding<Bool> {
        Binding(
            get: { controller.isEnabled },
            set: { controller.setEnabled($0) }
        )
    }

    var body: some View {
        SettingsSectionCard(
            title: "Show Hidden Files",
            subtitle: "Finder visibility control for system and project files.",
            statusText: controller.isEnabled ? "Visible" : "Hidden",
            tone: controller.isEnabled ? .positive : .neutral,
            iconName: "folder.badge.questionmark"
        ) {
            Toggle("Show hidden files in Finder", isOn: visibilityBinding)

            SettingsInlineMessage(text: "Finder relaunches automatically when the setting changes.", isError: false)

            if let lastError = controller.lastError {
                SettingsInlineMessage(text: lastError, isError: true)
            }
        }
    }
}

struct ShowFileExtensionsSettingsSection: View {
    @ObservedObject var controller: ShowFileExtensionsController
    @Environment(\.heyBarTheme) private var theme

    private var visibilityBinding: Binding<Bool> {
        Binding(
            get: { controller.isEnabled },
            set: { controller.setEnabled($0) }
        )
    }

    var body: some View {
        SettingsSectionCard(
            title: "Show File Extensions",
            subtitle: "Expose file names in full for support and technical work.",
            statusText: controller.isEnabled ? "Visible" : "Hidden",
            tone: controller.isEnabled ? .positive : .neutral,
            iconName: "doc.badge.gearshape"
        ) {
            Toggle("Show all filename extensions", isOn: visibilityBinding)

            SettingsInlineMessage(text: "Finder relaunches automatically when the setting changes.", isError: false)

            if let lastError = controller.lastError {
                SettingsInlineMessage(text: lastError, isError: true)
            }
        }
    }
}

struct NightShiftSettingsSection: View {
    @ObservedObject var controller: NightShiftController
    @Environment(\.heyBarTheme) private var theme

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { controller.isEnabled },
            set: { controller.setEnabled($0) }
        )
    }

    var body: some View {
        SettingsSectionCard(
            title: "Night Shift",
            subtitle: "Display warmth control backed by a private macOS bridge.",
            statusText: controller.isSupported ? (controller.isEnabled ? "On" : "Off") : "Unavailable",
            tone: controller.isSupported ? (controller.isEnabled ? .positive : .neutral) : .attention,
            iconName: "moon.stars.fill"
        ) {
            if controller.isSupported {
                Toggle("Enable Night Shift in HeyBar", isOn: enabledBinding)

                HStack {
                    Slider(value: $controller.strength, in: 0.1...1.0)
                    Text("\(Int(controller.strength * 100))%")
                        .themeSecondary(theme)
                        .frame(width: SettingsLayout.settingsMetricWidth, alignment: .trailing)
                }

                SettingsInlineMessage(text: "This control relies on private macOS frameworks and may stop working after a system update.", isError: false)
            } else {
                SettingsHelpStateCard(
                    title: "Night Shift unavailable",
                    message: "This Mac does not currently expose Night Shift control to HeyBar.",
                    iconName: "moon.stars",
                    tone: .attention,
                    tips: [
                        "This can vary by hardware and macOS version.",
                        "The rest of HeyBar will continue working normally."
                    ]
                )

                SettingsActionRow {
                    Button {
                        SystemSettingsNavigator.openDisplays()
                    } label: {
                        Label("Open Displays", systemImage: "display")
                    }
                    .buttonStyle(SettingsSecondaryButtonStyle())
                }
            }
        }
    }
}

struct KeyLightSettingsSection: View {
    @ObservedObject var controller: KeyLightController
    @Environment(\.heyBarTheme) private var theme

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { controller.isEnabled },
            set: { controller.setEnabled($0) }
        )
    }

    var body: some View {
        SettingsSectionCard(
            title: "Key Light",
            subtitle: "Keyboard backlight control with optional auto brightness.",
            statusText: controller.isSupported ? (controller.isEnabled ? "On" : "Off") : "Unavailable",
            tone: controller.isSupported ? (controller.isEnabled ? .positive : .neutral) : .attention,
            iconName: "keyboard"
        ) {
            if controller.isSupported {
                Toggle("Enable keyboard backlight control", isOn: enabledBinding)

                HStack {
                    Slider(value: $controller.brightness, in: 0.1...1.0)
                    Text("\(Int(controller.brightness * 100))%")
                        .themeSecondary(theme)
                        .frame(width: SettingsLayout.settingsMetricWidth, alignment: .trailing)
                }

                Toggle("Auto brightness", isOn: $controller.autoBrightness)

                SettingsInlineMessage(text: "This control relies on private macOS frameworks and may stop working after a system update.", isError: false)
            } else {
                SettingsHelpStateCard(
                    title: "Keyboard backlight unavailable",
                    message: "This Mac does not currently expose keyboard backlight control to HeyBar.",
                    iconName: "keyboard",
                    tone: .attention,
                    tips: [
                        "Desktop Macs and some keyboards may not support this feature.",
                        "You can still use the rest of the display controls."
                    ]
                )

                SettingsActionRow {
                    Button {
                        SystemSettingsNavigator.openKeyboard()
                    } label: {
                        Label("Open Keyboard", systemImage: "keyboard")
                    }
                    .buttonStyle(SettingsSecondaryButtonStyle())
                }
            }
        }
    }
}

struct HideDockSettingsSection: View {
    @ObservedObject var controller: HideDockController
    @Environment(\.heyBarTheme) private var theme

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { controller.isEnabled },
            set: { controller.setEnabled($0) }
        )
    }

    var body: some View {
        SettingsSectionCard(
            title: "Hide Dock",
            subtitle: "Automation-backed control for Dock auto-hide.",
            statusText: controller.isEnabled ? "On" : "Off",
            tone: controller.isEnabled ? .positive : .neutral,
            iconName: "dock.rectangle"
        ) {
            Toggle("Auto-hide the Dock", isOn: enabledBinding)
                .toggleStyle(.switch)

            SettingsInlineMessage(text: "Uses System Events automation. If macOS revokes access, the control will need permission again.", isError: false)

            SettingsActionRow {
                Button {
                    SystemSettingsNavigator.openAutomationPrivacy()
                } label: {
                    Label("Privacy Settings", systemImage: "lock.open")
                }
                .buttonStyle(SettingsSecondaryButtonStyle())

                Button {
                    controller.refresh()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(SettingsSecondaryButtonStyle())
            }

            if let lastError = controller.lastError {
                SettingsInlineMessage(text: lastError, isError: true)
            }
        }
    }
}

struct HideBarSettingsSection: View {
    @ObservedObject var controller: HideBarController
    @Environment(\.heyBarTheme) private var theme

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { controller.isEnabled },
            set: { controller.setEnabled($0) }
        )
    }

    var body: some View {
        SettingsSectionCard(
            title: "Hide Bar",
            subtitle: "Automation-backed control for menu bar auto-hide.",
            statusText: controller.isEnabled ? "On" : "Off",
            tone: controller.isEnabled ? .positive : .neutral,
            iconName: "menubar.rectangle"
        ) {
            Toggle("Auto-hide the menu bar", isOn: enabledBinding)
                .toggleStyle(.switch)

            SettingsInlineMessage(text: "Uses System Events automation. If macOS revokes access, the control will need permission again.", isError: false)

            SettingsActionRow {
                Button {
                    SystemSettingsNavigator.openAutomationPrivacy()
                } label: {
                    Label("Privacy Settings", systemImage: "lock.open")
                }
                .buttonStyle(SettingsSecondaryButtonStyle())

                Button {
                    controller.refresh()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(SettingsSecondaryButtonStyle())
            }

            if let lastError = controller.lastError {
                SettingsInlineMessage(text: lastError, isError: true)
            }
        }
    }
}
