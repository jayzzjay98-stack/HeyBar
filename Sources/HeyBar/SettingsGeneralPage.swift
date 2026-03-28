import SwiftUI

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

    var id: String { rawValue }

    var tileID: TileID {
        switch self {
        case .keepAwake:      return .keepAwake
        case .cleanKey:       return .cleanKey
        case .nightShift:     return .nightShift
        case .keyLight:       return .keyLight
        case .hiddenFiles:    return .hiddenFiles
        case .fileExtensions: return .fileExtensions
        case .hideDock:       return .hideDock
        case .hideBar:        return .hideBar
        }
    }

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
    let onQuit: (() -> Void)?

    @Environment(\.heyBarTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedFeature: CustomizeFeature? = CustomizeFeature.allCases.first
    @State private var keyMonitor: Any?
    @State private var orderedFeatures: [CustomizeFeature] = CustomizeFeature.allCases
    @State private var panelVisibility: [TileID: Bool] = [:]
    @State private var dragSourceIndex: Int? = nil
    @State private var dragOffsetY: CGFloat = 0
    @State private var dragTargetIndex: Int = 0
    private let sidebarRowH: CGFloat = 52

    var body: some View {
        HStack(spacing: 0) {
            featureSidebar
            Divider()
            detailPanel
        }
        .navigationTitle("Customize")
        .foregroundStyle(Color(nsColor: theme.settingsPrimaryTextColor))
        .onAppear {
            DispatchQueue.main.async {
                refreshControllers()
            }
            loadPanelState()
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
                VStack(spacing: 0) {
                    ForEach(Array(orderedFeatures.enumerated()), id: \.element) { idx, feature in
                        makeSidebarRow(feature: feature, index: idx)
                    }
                }
            }
        }
        .frame(width: SettingsLayout.generalSidebarWidth)
        .background(Color(nsColor: theme.settingsSidebarSurfaceColor))
    }

    @ViewBuilder
    private func makeSidebarRow(feature: CustomizeFeature, index: Int) -> some View {
        let isSrc = dragSourceIndex == index

        FeatureSidebarRow(
            feature: feature,
            isSelected: selectedFeature == feature,
            statusText: featureStatus(feature),
            isActive: featureIsActive(feature),
            toggleBinding: panelVisibilityBinding(for: feature),
            theme: theme
        )
        .background(
            selectedFeature == feature
            ? Color(nsColor: theme.settingsTint).opacity(0.08)
            : Color.clear
        )
        .opacity(isSrc ? 0.4 : 1.0)
        .zIndex(isSrc ? 2 : 0)
        .offset(y: isSrc ? dragOffsetY : sidebarItemOffset(for: index))
        .animation(
            isSrc ? nil : .interactiveSpring(response: 0.22, dampingFraction: 0.85),
            value: dragTargetIndex
        )
        .gesture(
            DragGesture(minimumDistance: 6)
                .onChanged { value in
                    if dragSourceIndex == nil { dragSourceIndex = index }
                    if dragSourceIndex == index {
                        dragOffsetY = value.translation.height
                        let moved = Int((dragOffsetY / sidebarRowH).rounded())
                        let newTarget = max(0, min(orderedFeatures.count - 1, index + moved))
                        if newTarget != dragTargetIndex { dragTargetIndex = newTarget }
                    }
                }
                .onEnded { _ in
                    let src = dragSourceIndex ?? index
                    let dst = dragTargetIndex
                    if dst != src {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            orderedFeatures.move(
                                fromOffsets: IndexSet(integer: src),
                                toOffset: dst > src ? dst + 1 : dst
                            )
                        }
                        savePanelState()
                    }
                    dragSourceIndex = nil
                    dragOffsetY = 0
                }
        )
        .onTapGesture {
            withAnimation(reduceMotion ? nil : .easeOut(duration: SettingsLayout.selectionDuration)) {
                selectedFeature = feature
            }
        }
    }

    private func sidebarItemOffset(for index: Int) -> CGFloat {
        guard let src = dragSourceIndex, src != dragTargetIndex else { return 0 }
        let dst = dragTargetIndex
        if src < dst {
            if index > src && index <= dst { return -sidebarRowH }
        } else {
            if index < src && index >= dst { return sidebarRowH }
        }
        return 0
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
        }
    }

    // MARK: Helpers

    private func loadPanelState() {
        let store = TileOrderStore.shared
        let tileIDToFeature: [TileID: CustomizeFeature] = Dictionary(
            uniqueKeysWithValues: CustomizeFeature.allCases.map { ($0.tileID, $0) }
        )
        let loaded = store.order.compactMap { tileIDToFeature[$0] }
        orderedFeatures = loaded.isEmpty ? CustomizeFeature.allCases : loaded
        panelVisibility = Dictionary(
            uniqueKeysWithValues: store.order.map { ($0, !store.hidden.contains($0)) }
        )
    }

    private func savePanelState() {
        let store = TileOrderStore.shared
        store.setOrder(orderedFeatures.map(\.tileID))
        for feature in orderedFeatures {
            store.setHidden(feature.tileID, !(panelVisibility[feature.tileID] ?? true))
        }
    }

    private func panelVisibilityBinding(for feature: CustomizeFeature) -> Binding<Bool> {
        Binding(
            get: { panelVisibility[feature.tileID] ?? true },
            set: { newVal in
                panelVisibility[feature.tileID] = newVal
                savePanelState()
            }
        )
    }

    private func moveSelection(by offset: Int) {
        let all = orderedFeatures
        if let current = selectedFeature,
           let idx = all.firstIndex(of: current) {
            let newIdx = max(0, min(all.count - 1, idx + offset))
            withAnimation(reduceMotion ? nil : .easeOut(duration: SettingsLayout.selectionDuration)) {
                selectedFeature = all[newIdx]
            }
        } else {
            selectedFeature = all.first ?? CustomizeFeature.allCases[0]
        }
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

// MARK: - Feature Sidebar Row

private struct FeatureSidebarRow: View {
    let feature: CustomizeFeature
    let isSelected: Bool
    let statusText: String
    let isActive: Bool
    let toggleBinding: Binding<Bool>
    let theme: AppTheme

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(isSelected ? Color(nsColor: theme.settingsTint) : .clear)
                    .frame(width: 3, height: 36)

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

                Toggle("", isOn: toggleBinding)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .scaleEffect(0.75)
                    .frame(width: 36)

                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(nsColor: theme.settingsPrimaryTextColor).opacity(0.3))
                    .frame(width: 20)
                    .padding(.trailing, 8)
            }
            .frame(height: 52)
            .contentShape(Rectangle())

            Rectangle()
                .fill(Color(nsColor: theme.settingsSeparatorColor))
                .frame(height: 1)
                .padding(.leading, 46)
        }
    }
}

