import SwiftUI

struct PanelSettingsPage: View {
    @Environment(\.heyBarTheme) private var theme

    @State private var items: [TileItem] = []

    struct TileItem: Identifiable {
        let id: TileID
        var isVisible: Bool

        var name: String {
            switch id {
            case .keepAwake:      return "Keep Awake"
            case .hiddenFiles:    return "Hidden Files"
            case .fileExtensions: return "File Extensions"
            case .keyLight:       return "Key Light"
            case .nightShift:     return "Night Shift"
            case .hideDock:       return "Hide Dock"
            case .hideBar:        return "Hide Bar"
            case .cleanKey:       return "CleanKey"
            }
        }

        var icon: String {
            switch id {
            case .keepAwake:      return "sparkles.tv"
            case .hiddenFiles:    return "folder.badge.questionmark"
            case .fileExtensions: return "doc.badge.gearshape"
            case .keyLight:       return "keyboard"
            case .nightShift:     return "moon.stars.fill"
            case .hideDock:       return "dock.rectangle"
            case .hideBar:        return "menubar.rectangle"
            case .cleanKey:       return "sparkles"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quick Controls Layout")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color(nsColor: theme.settingsPrimaryTextColor))
                    Text("\(items.filter(\.isVisible).count) of \(items.count) visible")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(nsColor: theme.settingsPrimaryTextColor).opacity(0.45))
                }
                Spacer()
            }
            .padding(.horizontal, SettingsLayout.contentPadding)
            .padding(.top, SettingsLayout.contentPadding)
            .padding(.bottom, 16)

            // Instructions
            HStack {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                Text("Drag rows to reorder. Toggle to show or hide each control in the panel.")
                    .font(.system(size: 12))
                Spacer()
            }
            .foregroundStyle(Color(nsColor: theme.settingsPrimaryTextColor).opacity(0.45))
            .padding(.horizontal, SettingsLayout.contentPadding)
            .padding(.bottom, 12)

            // Tile list with drag-to-reorder
            List {
                ForEach($items) { $item in
                    TileRow(item: $item, theme: theme, onToggle: saveState)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowSeparatorTint(Color(nsColor: theme.settingsSidebarBorderColor).opacity(0.5))
                }
                .onMove(perform: moveItems)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(
                RoundedRectangle(cornerRadius: SettingsLayout.contentCornerRadius - 6, style: .continuous)
                    .fill(Color(nsColor: theme.settingsChromeSurfaceColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: SettingsLayout.contentCornerRadius - 6, style: .continuous)
                            .stroke(Color(nsColor: theme.settingsSidebarBorderColor).opacity(0.6), lineWidth: 1)
                    )
            )
            .padding(.horizontal, SettingsLayout.contentPadding)
            .padding(.bottom, SettingsLayout.contentPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { loadState() }
    }

    private func loadState() {
        let store = TileOrderStore.shared
        items = store.order.map { id in
            TileItem(id: id, isVisible: !store.hidden.contains(id))
        }
    }

    private func saveState() {
        let store = TileOrderStore.shared
        store.setOrder(items.map(\.id))
        for item in items {
            store.setHidden(item.id, !item.isVisible)
        }
    }

    private func moveItems(from offsets: IndexSet, to destination: Int) {
        items.move(fromOffsets: offsets, toOffset: destination)
        saveState()
    }
}

private struct TileRow: View {
    @Binding var item: PanelSettingsPage.TileItem
    let theme: AppTheme
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Checkmark = visible / empty circle = hidden
            Button {
                item.isVisible.toggle()
                onToggle()
            } label: {
                Image(systemName: item.isVisible ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(
                        item.isVisible
                        ? Color(nsColor: theme.settingsTint)
                        : Color(nsColor: theme.settingsPrimaryTextColor).opacity(0.25)
                    )
            }
            .buttonStyle(.plain)

            Image(systemName: item.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(
                    item.isVisible
                    ? Color(nsColor: theme.settingsTint)
                    : Color(nsColor: theme.settingsPrimaryTextColor).opacity(0.3)
                )
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            item.isVisible
                            ? Color(nsColor: theme.settingsTint).opacity(0.12)
                            : Color(nsColor: theme.settingsPrimaryTextColor).opacity(0.06)
                        )
                )

            Text(item.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(
                    item.isVisible
                    ? Color(nsColor: theme.settingsPrimaryTextColor)
                    : Color(nsColor: theme.settingsPrimaryTextColor).opacity(0.35)
                )

            Spacer()

            // Drag handle
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(nsColor: theme.settingsPrimaryTextColor).opacity(0.3))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(nsColor: theme.settingsChromeSurfaceColor))
    }
}
