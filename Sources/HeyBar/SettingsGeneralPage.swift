import SwiftUI
import ServiceManagement

// MARK: - Feature List

private enum CustomizeFeature: String, CaseIterable, Identifiable {
    case keepAwake      = "Keep Awake"
    case cleanKey       = "CleanKey"
    case nightShift     = "Night Shift"
    case keyLight       = "Key Light"
    case hiddenFiles    = "Hidden Files"
    case fileExtensions = "File Extensions"
    case hideDock       = "Hide Dock"
    case hideBar        = "Hide Bar"
    case launchAtLogin  = "Launch at Login"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .keepAwake:      return "sparkles.tv"
        case .cleanKey:       return "sparkles"
        case .nightShift:     return "moon.stars.fill"
        case .keyLight:       return "keyboard"
        case .hiddenFiles:    return "folder.badge.questionmark"
        case .fileExtensions: return "doc.badge.gearshape"
        case .hideDock:       return "dock.rectangle"
        case .hideBar:        return "menubar.rectangle"
        case .launchAtLogin:  return "power.circle"
        }
    }
}

// MARK: - Arrow key codes

private enum ArrowKey {
    static let down: UInt16 = 125
    static let up:   UInt16 = 126
}

// MARK: - Main Page

struct GeneralSettingsPage: View {
    @EnvironmentObject var model: AppModel
    @Binding var launchAtLogin: Bool
    @Binding var launchAtLoginError: String?
    let onQuit: (() -> Void)?

    @Environment(\.heyBarTheme) private var theme
    @State private var selectedFeature: CustomizeFeature? = .keepAwake
    @State private var keyMonitor: Any?

    var body: some View {
        HStack(spacing: 0) {
            featureSidebar
            Divider()
            detailPanel
        }
        .navigationTitle("Customize")
        .foregroundStyle(Color(nsColor: theme.settingsPrimaryTextColor))
        .onAppear {
            refreshControllers()
            guard keyMonitor == nil else { return }
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                guard event.keyCode == ArrowKey.down || event.keyCode == ArrowKey.up
                else { return event }
                if let fr = NSApp.keyWindow?.firstResponder,
                   fr is NSTextView || fr is NSTextField { return event }
                if event.keyCode == ArrowKey.down { moveSelection(by:  1) }
                else                              { moveSelection(by: -1) }
                return nil
            }
        }
        .onDisappear {
            if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
        }
    }

    // MARK: Sidebar

    private var featureSidebar: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(CustomizeFeature.allCases) { feature in
                        FeatureSidebarRow(
                            feature: feature,
                            isSelected: selectedFeature == feature,
                            statusText: featureStatus(feature),
                            isActive: featureIsActive(feature),
                            toggleBinding: featureToggleBinding(feature),
                            theme: theme
                        ) {
                            withAnimation(.easeOut(duration: 0.12)) {
                                selectedFeature = feature
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            Divider()
            activeCountFooter
        }
        .frame(width: 240)
        .background(Color(nsColor: theme.settingsSidebarSurfaceColor))
    }

    private var activeCountFooter: some View {
        let activeCount = CustomizeFeature.allCases.filter { featureIsActive($0) }.count
        let total = CustomizeFeature.allCases.count
        return HStack(spacing: 5) {
            Circle()
                .fill(activeCount > 0
                      ? Color(nsColor: theme.settingsTint)
                      : Color(nsColor: theme.settingsPrimaryTextColor).opacity(0.25))
                .frame(width: 5, height: 5)
            Text("\(activeCount) of \(total) active")
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(Color(nsColor: theme.settingsPrimaryTextColor).opacity(0.45))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: Detail Panel

    @ViewBuilder
    private var detailPanel: some View {
        if let feature = selectedFeature {
            SettingsPageScroll {
                featureDetailContent(feature)
            }
        } else {
            VStack(spacing: 10) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(Color(nsColor: theme.settingsPrimaryTextColor).opacity(0.2))
                Text("Select a feature to configure")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(nsColor: theme.settingsPrimaryTextColor).opacity(0.3))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func featureDetailContent(_ feature: CustomizeFeature) -> some View {
        switch feature {
        case .keepAwake:      KeepAwakeSettingsSection(controller: model.keepAwake)
        case .cleanKey:       CleanKeySettingsSection(controller: model.cleanKey)
        case .nightShift:     NightShiftSettingsSection(controller: model.nightShift)
        case .keyLight:       KeyLightSettingsSection(controller: model.keyLight)
        case .hiddenFiles:    ShowHiddenFilesSettingsSection(controller: model.hiddenFiles)
        case .fileExtensions: ShowFileExtensionsSettingsSection(controller: model.fileExtensions)
        case .hideDock:       HideDockSettingsSection(controller: model.hideDock)
        case .hideBar:        HideBarSettingsSection(controller: model.hideBar)
        case .launchAtLogin:
            LaunchAtLoginSection(
                launchAtLogin: $launchAtLogin,
                launchAtLoginError: $launchAtLoginError,
                onToggle: applyLaunchAtLogin
            )
        }
    }

    // MARK: Helpers

    private func moveSelection(by offset: Int) {
        let all = CustomizeFeature.allCases
        guard let current = selectedFeature,
              let idx = all.firstIndex(of: current) else {
            selectedFeature = all.first
            return
        }
        let newIdx = max(0, min(all.count - 1, idx + offset))
        withAnimation(.easeOut(duration: 0.12)) { selectedFeature = all[newIdx] }
    }

    private func featureStatus(_ feature: CustomizeFeature) -> String {
        switch feature {
        case .keepAwake:      return model.keepAwake.isEnabled ? "Active" : "Idle"
        case .cleanKey:       return model.cleanKey.isCleaning ? "Cleaning" : "Idle"
        case .nightShift:     return model.nightShift.isEnabled ? "On" : "Off"
        case .keyLight:       return model.keyLight.isEnabled ? "On" : "Off"
        case .hiddenFiles:    return model.hiddenFiles.isEnabled ? "Visible" : "Hidden"
        case .fileExtensions: return model.fileExtensions.isEnabled ? "Visible" : "Hidden"
        case .hideDock:       return model.hideDock.isEnabled ? "On" : "Off"
        case .hideBar:        return model.hideBar.isEnabled ? "On" : "Off"
        case .launchAtLogin:  return launchAtLogin ? "Enabled" : "Disabled"
        }
    }

    private func featureIsActive(_ feature: CustomizeFeature) -> Bool {
        switch feature {
        case .keepAwake:      return model.keepAwake.isEnabled
        case .cleanKey:       return model.cleanKey.isCleaning
        case .nightShift:     return model.nightShift.isEnabled
        case .keyLight:       return model.keyLight.isEnabled
        case .hiddenFiles:    return model.hiddenFiles.isEnabled
        case .fileExtensions: return model.fileExtensions.isEnabled
        case .hideDock:       return model.hideDock.isEnabled
        case .hideBar:        return model.hideBar.isEnabled
        case .launchAtLogin:  return launchAtLogin
        }
    }

    private func applyLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else       { try SMAppService.mainApp.unregister() }
            launchAtLogin = enabled
            launchAtLoginError = nil
        } catch {
            launchAtLoginError = UserFacingMessages.launchAtLoginUpdateFailed(error.localizedDescription)
        }
    }

    // Capture controllers directly to avoid retaining the model inside Binding closures.
    private func featureToggleBinding(_ feature: CustomizeFeature) -> Binding<Bool> {
        switch feature {
        case .keepAwake:
            let c = model.keepAwake
            return Binding(get: { c.isEnabled }, set: { c.isEnabled = $0 })
        case .cleanKey:
            let c = model.cleanKey
            return Binding(
                get: { c.isCleaning },
                set: { newVal in if newVal { _ = c.startCleaning() } else { c.stopCleaning() } }
            )
        case .nightShift:
            let c = model.nightShift
            return Binding(get: { c.isEnabled }, set: { c.setEnabled($0) })
        case .keyLight:
            let c = model.keyLight
            return Binding(get: { c.isEnabled }, set: { c.setEnabled($0) })
        case .hiddenFiles:
            let c = model.hiddenFiles
            return Binding(get: { c.isEnabled }, set: { c.setEnabled($0) })
        case .fileExtensions:
            let c = model.fileExtensions
            return Binding(get: { c.isEnabled }, set: { c.setEnabled($0) })
        case .hideDock:
            let c = model.hideDock
            return Binding(get: { c.isEnabled }, set: { c.setEnabled($0) })
        case .hideBar:
            let c = model.hideBar
            return Binding(get: { c.isEnabled }, set: { c.setEnabled($0) })
        case .launchAtLogin:
            return Binding(
                get: { launchAtLogin },
                set: { applyLaunchAtLogin($0) }
            )
        }
    }

    private func refreshControllers() {
        model.hiddenFiles.refresh()
        model.fileExtensions.refresh()
        model.nightShift.refresh()
        model.keyLight.refresh()
        model.hideDock.refresh()
        model.hideBar.refresh()
        model.cleanKey.refreshPermissionStatus()
    }
}

// MARK: - Sidebar Row

private struct FeatureSidebarRow: View {
    let feature: CustomizeFeature
    let isSelected: Bool
    let statusText: String
    let isActive: Bool
    let toggleBinding: Binding<Bool>
    let theme: AppTheme
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        ZStack(alignment: .trailing) {
            Button(action: action) {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isSelected ? Color(nsColor: theme.settingsTint) : .clear)
                        .frame(width: 3, height: 34)

                    Image(systemName: feature.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(
                            isSelected
                            ? Color(nsColor: theme.settingsTint)
                            : Color(nsColor: theme.settingsPrimaryTextColor).opacity(0.75)
                        )
                        .frame(width: 30, height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    isSelected
                                    ? Color(nsColor: theme.settingsTint).opacity(0.15)
                                    : Color(nsColor: theme.settingsPrimaryTextColor).opacity(0.08)
                                )
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.rawValue)
                            .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                            .foregroundStyle(Color(nsColor: theme.settingsPrimaryTextColor))
                            .lineLimit(1)
                        Text(statusText)
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundStyle(
                                isActive
                                ? Color(nsColor: theme.settingsTint)
                                : Color(nsColor: theme.settingsPrimaryTextColor).opacity(0.4)
                            )
                    }

                    Spacer()
                    Color.clear.frame(width: 40)
                }
                .frame(height: 48)
                .background(
                    isSelected
                    ? Color(nsColor: theme.settingsTint).opacity(0.08)
                    : isHovered
                        ? Color(nsColor: theme.settingsPrimaryTextColor).opacity(0.05)
                        : Color.clear
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Toggle("", isOn: toggleBinding)
                .toggleStyle(.switch)
                .labelsHidden()
                .scaleEffect(0.75)
                .padding(.trailing, 10)
        }
        .onHover { isHovered = $0 }
    }
}

// MARK: - Launch at Login Section

private struct LaunchAtLoginSection: View {
    @Binding var launchAtLogin: Bool
    @Binding var launchAtLoginError: String?
    let onToggle: (Bool) -> Void
    @Environment(\.heyBarTheme) private var theme

    var body: some View {
        SettingsSectionCard(
            title: "Launch at Login",
            subtitle: "Make HeyBar available as soon as your Mac session starts.",
            statusText: launchAtLogin ? "Enabled" : "Disabled",
            tone: launchAtLogin ? .positive : .neutral,
            iconName: "power.circle"
        ) {
            Toggle(isOn: Binding(
                get: { launchAtLogin },
                set: { onToggle($0) }
            )) {
                Label("Launch at Login", systemImage: "power.circle")
            }
            .toggleStyle(.switch)

            if let launchAtLoginError {
                SettingsInlineMessage(text: launchAtLoginError, isError: true)
            }
        }
    }
}
