import AppKit
@preconcurrency import Combine

@MainActor
final class QuickControlsViewController: NSViewController {
    private let model: AppModel
    private let openSettings: () -> Void

    var onClose: (() -> Void)?

    private let backgroundView = GradientPanelBackgroundView()
    private let closeButton = NSButton()
    private let quitButton = NSButton(title: "Quit", target: nil, action: nil)
    private let settingsButton = NSButton(title: "Settings", target: nil, action: nil)

    // Toast notification overlay
    private let toastView = NSView()
    private let toastLabel = NSTextField(labelWithString: "")

    // Countdown refresh timer (runs while panel is visible)
    private var displayTimer: Timer?
    private var themeCancellable: AnyCancellable?
    nonisolated(unsafe) private var tileOrderObserver: NSObjectProtocol?

    // Cached state to skip redundant work in refresh()
    private var lastAppliedTheme: AppTheme?
    private var tooltipUpdateCounter = 0

    // Static NSImages that never change — created once, reused forever
    private lazy var settingsIcon = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Settings")
    private lazy var quitIcon = NSImage(systemSymbolName: "power", accessibilityDescription: "Quit")

    // All tile buttons keyed by TileID
    private lazy var allTileButtons: [TileID: FeatureTileButton] = [
        .keepAwake: FeatureTileButton(title: "Keep Awake", symbolName: "sparkles.tv", caption: "Session"),
        .hiddenFiles: FeatureTileButton(title: "Hidden Files", symbolName: "folder.badge.questionmark", caption: "Finder"),
        .fileExtensions: FeatureTileButton(title: "File Extensions", symbolName: "doc.badge.gearshape", caption: "Finder"),
        .keyLight: FeatureTileButton(title: "Key Light", symbolName: "keyboard", caption: "Display"),
        .nightShift: FeatureTileButton(title: "Night Shift", symbolName: "moon.stars.fill", caption: "Display"),
        .hideDock: FeatureTileButton(title: "Hide Dock", symbolName: "dock.rectangle", caption: "Automation"),
        .hideBar: FeatureTileButton(title: "Hide Bar", symbolName: "menubar.rectangle", caption: "Automation"),
        .cleanKey: FeatureTileButton(title: "CleanKey", symbolName: "sparkles", caption: "Apps")
    ]

    // Content stack (stored so we can add/remove tile rows)
    private var contentStack: NSStackView!
    private var currentTileRows: [NSStackView] = []


    init(model: AppModel, openSettings: @escaping () -> Void) {
        self.model = model
        self.openSettings = openSettings
        super.init(nibName: nil, bundle: nil)
        themeCancellable = model.$selectedThemeID
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refresh() }
        tileOrderObserver = DistributedNotificationCenter.default().addObserver(
            forName: TileOrderStore.didChangeNotification,
            object: Bundle.main.bundleIdentifier,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleTileOrderChange()
            }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        themeCancellable?.cancel()
        tileOrderObserver.map { DistributedNotificationCenter.default().removeObserver($0) }
    }

    override func loadView() {
        view = NSView(frame: NSRect(origin: .zero, size: QuickControlsLayout.panelSize))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor

        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.wantsLayer = true

        setupCloseButton()
        setupFooterButtons()
        setupToastView()

        // Set height constraints on all tile buttons
        for button in allTileButtons.values {
            button.heightAnchor.constraint(equalToConstant: QuickControlsLayout.tileHeight).isActive = true
        }

        configureTileActions()

        let topBar = makeTopBar()
        let footerBar = makeFooterBar()

        contentStack = NSStackView(views: [topBar, footerBar])
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.orientation = .vertical
        contentStack.alignment = .leading
        contentStack.spacing = QuickControlsLayout.stackSpacing

        // Insert tile rows between topBar and footerBar
        rebuildTileGrid()

        backgroundView.addSubview(contentStack)
        view.addSubview(backgroundView)
        view.addSubview(toastView)

        activateLayoutConstraints(topBar: topBar, footerBar: footerBar)

        refresh()
    }

    private func setupCloseButton() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.bezelStyle = .regularSquare
        closeButton.isBordered = false
        closeButton.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Close")
        closeButton.target = self
        closeButton.action = #selector(closePanel)
        closeButton.wantsLayer = true
        closeButton.layer?.cornerRadius = QuickControlsLayout.closeButtonSize / 2
        closeButton.setAccessibilityLabel("Close")
        closeButton.setAccessibilityHelp("Close the Quick Controls panel")
        closeButton.widthAnchor.constraint(equalToConstant: QuickControlsLayout.closeButtonSize).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: QuickControlsLayout.closeButtonSize).isActive = true
    }

    private func setupFooterButtons() {
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.isBordered = false
        settingsButton.wantsLayer = true
        settingsButton.layer?.cornerRadius = 10
        settingsButton.imagePosition = .imageLeading
        settingsButton.imageHugsTitle = true
        settingsButton.alignment = .center
        settingsButton.target = self
        settingsButton.action = #selector(openSettingsAction)
        settingsButton.setAccessibilityLabel("Settings")
        settingsButton.setAccessibilityHelp("Open HeyBar settings")

        quitButton.translatesAutoresizingMaskIntoConstraints = false
        quitButton.isBordered = false
        quitButton.wantsLayer = true
        quitButton.layer?.cornerRadius = 10
        quitButton.imagePosition = .imageLeading
        quitButton.imageHugsTitle = true
        quitButton.alignment = .center
        quitButton.target = self
        quitButton.action = #selector(quitApp)
        quitButton.setAccessibilityLabel("Quit HeyBar")
        quitButton.setAccessibilityHelp("Quit HeyBar completely")
    }

    private func setupToastView() {
        toastView.translatesAutoresizingMaskIntoConstraints = false
        toastView.wantsLayer = true
        toastView.layer?.cornerRadius = 14
        toastView.layer?.masksToBounds = true
        toastView.alphaValue = 0

        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        toastLabel.font = .systemFont(ofSize: 12, weight: .medium)
        toastLabel.textColor = .white
        toastLabel.alignment = .center
        toastView.addSubview(toastLabel)
    }

    private func makeTopBar() -> NSStackView {
        let bar = NSStackView(views: [NSView(), closeButton])
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.orientation = .horizontal
        bar.alignment = .centerY
        bar.spacing = 8
        return bar
    }

    private func makeFooterBar() -> NSStackView {
        let bar = NSStackView(views: [quitButton, NSView(), settingsButton])
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.orientation = .horizontal
        bar.alignment = .centerY
        bar.spacing = 10
        return bar
    }

    private func activateLayoutConstraints(topBar: NSStackView, footerBar: NSStackView) {
        let constraints: [NSLayoutConstraint] = [
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: QuickControlsLayout.panelInset),
            contentStack.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -QuickControlsLayout.panelInset),
            contentStack.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: QuickControlsLayout.panelInset),
            contentStack.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -QuickControlsLayout.panelInset),

            topBar.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            footerBar.widthAnchor.constraint(equalTo: contentStack.widthAnchor),

            quitButton.widthAnchor.constraint(greaterThanOrEqualToConstant: QuickControlsLayout.quitButtonMinWidth),
            quitButton.heightAnchor.constraint(equalToConstant: QuickControlsLayout.footerButtonHeight),
            settingsButton.widthAnchor.constraint(greaterThanOrEqualToConstant: QuickControlsLayout.settingsButtonMinWidth),
            settingsButton.heightAnchor.constraint(equalToConstant: QuickControlsLayout.footerButtonHeight),

            toastLabel.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: 16),
            toastLabel.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: -16),
            toastLabel.centerYAnchor.constraint(equalTo: toastView.centerYAnchor),
            toastView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
            toastView.heightAnchor.constraint(equalToConstant: 30),
        ]
        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Tile Grid

    private func rebuildTileGrid() {
        TileOrderStore.shared.reload()

        // Remove old rows
        for row in currentTileRows {
            contentStack.removeArrangedSubview(row)
            row.removeFromSuperview()
        }
        currentTileRows.removeAll()

        let store = TileOrderStore.shared
        let orderedIDs = store.order.filter { !store.hidden.contains($0) }

        // Build rows of 2
        var rows: [NSStackView] = []
        var i = 0
        while i < orderedIDs.count {
            let left = orderedIDs[i]
            let right = i + 1 < orderedIDs.count ? orderedIDs[i + 1] : nil

            let buttons: [NSView]
            if let right = right, let leftBtn = allTileButtons[left], let rightBtn = allTileButtons[right] {
                buttons = [leftBtn, rightBtn]
            } else if let leftBtn = allTileButtons[left] {
                buttons = [leftBtn]
            } else {
                i += 2
                continue
            }

            let row = makeTileRow(buttons)
            rows.append(row)
            i += 2
        }

        // Insert rows between topBar and footerBar, then activate width constraints
        let insertIndex = contentStack.arrangedSubviews.count - 1 // before footerBar
        for (idx, row) in rows.enumerated() {
            contentStack.insertArrangedSubview(row, at: insertIndex + idx)
            // Activate width constraint AFTER adding to the same hierarchy
            row.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true
        }
        currentTileRows = rows
    }

    private func handleTileOrderChange() {
        TileOrderStore.shared.reload()
        rebuildTileGrid()
        view.layoutSubtreeIfNeeded()
        refresh()
    }


    // MARK: - Computed Size

    /// Rebuild the tile grid and return the size the panel should use.
    /// Call this BEFORE making the panel visible so the layout is correct on first show.
    func prepareForShow() -> NSSize {
        rebuildTileGrid()
        view.layoutSubtreeIfNeeded()
        return computedPanelSize()
    }

    private func computedPanelSize() -> NSSize {
        TileOrderStore.shared.reload()
        let store = TileOrderStore.shared
        let visibleCount = store.order.filter { !store.hidden.contains($0) }.count
        let numRows = max(1, (visibleCount + 1) / 2)
        let L = QuickControlsLayout.self
        let stackH = L.closeButtonSize
            + CGFloat(numRows + 1) * L.stackSpacing
            + CGFloat(numRows) * L.tileHeight
            + L.footerButtonHeight
        let panelH = 2 * L.panelInset + stackH
        return NSSize(width: L.panelSize.width, height: panelH)
    }

    // MARK: - View Lifecycle

    override func viewWillAppear() {
        super.viewWillAppear()
        startDisplayTimer()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        stopDisplayTimer()
    }

    private func startDisplayTimer() {
        displayTimer?.invalidate()
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refresh() }
        }
        RunLoop.main.add(timer, forMode: .common)
        displayTimer = timer
    }

    private func stopDisplayTimer() {
        displayTimer?.invalidate()
        displayTimer = nil
    }

    // MARK: - Refresh

    func refresh() {
        TileOrderStore.shared.reload()

        // Sync fast controllers from system so tiles reflect external changes
        // (e.g. user toggled Night Shift from System Settings while panel is open).
        model.nightShift.refresh()
        model.keyLight.refresh()

        let theme = model.selectedTheme

        // Only re-apply chrome/background when theme actually changes.
        if theme != lastAppliedTheme {
            applyTheme(theme)
            lastAppliedTheme = theme
        }

        let store = TileOrderStore.shared
        for (id, button) in allTileButtons where !store.hidden.contains(id) {
            applyTileStateForID(id, button: button, theme: theme)
        }

        // Tooltips almost never change — update every 10 seconds instead of every second.
        tooltipUpdateCounter += 1
        if tooltipUpdateCounter >= 10 {
            tooltipUpdateCounter = 0
            updateTooltips()
        }
    }

    private func applyTileStateForID(_ id: TileID, button: FeatureTileButton, theme: AppTheme) {
        switch id {
        case .keepAwake:
            let keepAwakeOn = model.keepAwake.isEnabled
            let keepAwakeBadge = keepAwakeCountdownText() ?? (keepAwakeOn ? "ON" : "OFF")
            applyTileState(
                QuickControlsTileState(badgeText: keepAwakeBadge, badgeStyle: keepAwakeOn ? .on : .off, isEnabled: true, alternate: false),
                to: button,
                theme: theme,
                symbolName: keepAwakeOn ? "bolt.fill" : "sparkles.tv",
                captionOverride: shortcutLabel(for: .keepAwake)
            )

        case .hiddenFiles:
            let hiddenOn = model.hiddenFiles.isEnabled
            applyTileState(.standard(isOn: hiddenOn, alternate: true), to: button, theme: theme,
                symbolName: hiddenOn ? "folder.fill.badge.questionmark" : "folder.badge.questionmark",
                captionOverride: shortcutLabel(for: .showHiddenFiles)
            )

        case .fileExtensions:
            let extOn = model.fileExtensions.isEnabled
            applyTileState(.standard(isOn: extOn, alternate: true), to: button, theme: theme,
                captionOverride: shortcutLabel(for: .showFileExtensions)
            )

        case .keyLight:
            applyTileState(
                .supportedFeature(isSupported: model.keyLight.isSupported, isOn: model.keyLight.isEnabled, alternate: false),
                to: button,
                theme: theme,
                captionOverride: shortcutLabel(for: .keyLight)
            )

        case .nightShift:
            let nightOn = model.nightShift.isEnabled
            applyTileState(
                .supportedFeature(isSupported: model.nightShift.isSupported, isOn: nightOn, alternate: false),
                to: button,
                theme: theme,
                symbolName: nightOn ? "moon.stars.fill" : "moon.stars",
                captionOverride: shortcutLabel(for: .nightShift)
            )

        case .hideDock:
            let dockOn = model.hideDock.isEnabled
            applyTileState(.standard(isOn: dockOn, alternate: true), to: button, theme: theme,
                symbolName: dockOn ? "dock.arrow.down.rectangle" : "dock.rectangle",
                captionOverride: shortcutLabel(for: .hideDock)
            )

        case .hideBar:
            let barOn = model.hideBar.isEnabled
            applyTileState(.standard(isOn: barOn, alternate: false), to: button, theme: theme,
                symbolName: barOn ? "menubar.arrow.up.rectangle" : "menubar.rectangle",
                captionOverride: shortcutLabel(for: .hideBar)
            )

        case .cleanKey:
            applyTileState(
                QuickControlsTileState(
                    badgeText: model.cleanKey.isCleaning ? model.cleanKey.remainingBadgeText : "START",
                    badgeStyle: model.cleanKey.isCleaning ? .on : .off,
                    isEnabled: true,
                    alternate: true
                ),
                to: button,
                theme: theme,
                symbolName: model.cleanKey.isCleaning ? "lock.fill" : "sparkles",
                captionOverride: shortcutLabel(for: .cleanKey) ?? "Cleaning"
            )
        }
    }

    private func updateTooltips() {
        allTileButtons[.keyLight]?.toolTip = model.keyLight.isSupported
            ? "Toggle keyboard backlight"
            : "Key Light is unavailable on this Mac"
        allTileButtons[.nightShift]?.toolTip = model.nightShift.isSupported
            ? "Toggle Night Shift"
            : "Night Shift is unavailable on this Mac"
        allTileButtons[.hideDock]?.toolTip = model.hideDock.lastError == nil
            ? "Toggle Dock auto-hide"
            : "Automation permission may be required"
        allTileButtons[.hideBar]?.toolTip = model.hideBar.lastError == nil
            ? "Toggle menu bar auto-hide"
            : "Automation permission may be required"
        allTileButtons[.cleanKey]?.toolTip = model.cleanKey.isCleaning
            ? "Stop CleanKey mode"
            : "Start CleanKey mode"
        quitButton.toolTip = "Quit HeyBar"
        settingsButton.toolTip = "Open Settings"
    }

    private func keepAwakeCountdownText() -> String? {
        guard model.keepAwake.isEnabled,
              model.keepAwake.usesDurationMode,
              model.keepAwake.durationMinutes > 0,
              !model.keepAwake.scheduleEnabled,
              let expiry = model.keepAwake.expiryDate else { return nil }
        let remaining = expiry.timeIntervalSinceNow
        guard remaining > 0 else { return nil }
        let mins = Int(remaining / 60)
        let secs = Int(remaining) % 60
        return mins > 0 ? "\(mins)m" : "\(secs)s"
    }

    private func shortcutLabel(for action: ShortcutAction) -> String? {
        model.shortcuts.shortcut(for: action)?.displayString
    }

    // MARK: - Feature Toggles

    @objc private func toggleKeepAwake() {
        model.toggleKeepAwake()
        refresh()
        showToast(model.keepAwake.isEnabled ? "Keep Awake — On" : "Keep Awake — Off")
    }

    @objc private func toggleHiddenFiles() {
        model.toggleHiddenFiles()
        refresh()
        showToast(model.hiddenFiles.isEnabled ? "Hidden Files — Visible" : "Hidden Files — Hidden")
    }

    @objc private func toggleFileExtensions() {
        model.toggleFileExtensions()
        refresh()
        showToast(model.fileExtensions.isEnabled ? "File Extensions — Visible" : "File Extensions — Hidden")
    }

    @objc private func toggleKeyLight() {
        guard model.keyLight.isSupported else {
            showToast("Key Light unavailable on this Mac")
            return
        }
        model.toggleKeyLight()
        refresh()
        showToast(model.keyLight.isEnabled ? "Key Light — On" : "Key Light — Off")
    }

    @objc private func toggleNightShift() {
        guard model.nightShift.isSupported else {
            showToast("Night Shift unavailable on this Mac")
            return
        }
        model.toggleNightShift()
        refresh()
        showToast(model.nightShift.isEnabled ? "Night Shift — On" : "Night Shift — Off")
    }

    @objc private func toggleHideDock() {
        model.toggleHideDock()
        refresh()
        if let lastError = model.hideDock.lastError {
            showToast(automationToastMessage(for: lastError))
        } else {
            showToast(model.hideDock.isEnabled ? "Hide Dock — On" : "Hide Dock — Off")
        }
    }

    @objc private func toggleHideBar() {
        model.toggleHideBar()
        refresh()
        if let lastError = model.hideBar.lastError {
            showToast(automationToastMessage(for: lastError))
        } else {
            showToast(model.hideBar.isEnabled ? "Hide Bar — On" : "Hide Bar — Off")
        }
    }

    @objc private func openCleanKey() {
        if model.cleanKey.isCleaning {
            model.stopCleanKey()
            refresh()
            showToast("CleanKey stopped")
            return
        }

        let started = model.startCleanKey()
        refresh()
        if started {
            onClose?()
        } else {
            showToast(model.cleanKey.lastError ?? "CleanKey could not start")
        }
    }

    // MARK: - Toast

    private func showToast(_ message: String) {
        toastLabel.stringValue = message
        toastView.layer?.removeAllAnimations()

        // Announce to VoiceOver
        NSAccessibility.post(
            element: NSApp as Any,
            notification: NSAccessibility.Notification(rawValue: "AXAnnouncementRequested"),
            userInfo: [
                .announcement: message as NSString,
                .priority: NSAccessibilityPriorityLevel.high.rawValue as NSNumber
            ]
        )

        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            toastView.alphaValue = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
                self?.toastView.alphaValue = 0
            }
            return
        }

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = QuickControlsLayout.toastFadeInDuration
            toastView.animator().alphaValue = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = QuickControlsLayout.toastFadeOutDuration
                self?.toastView.animator().alphaValue = 0
            }
        }
    }

    private func automationToastMessage(for error: String) -> String {
        if error == UserFacingMessages.automationPermissionRequired {
            return "Allow Automation in Privacy & Security"
        }
        return error
    }

    // MARK: - Actions

    @objc private func openSettingsAction() {
        openSettings()
        onClose?()
    }

    @objc private func quitApp() {
        onClose?()
        model.onQuit?()
    }

    @objc private func closePanel() {
        onClose?()
    }

    @objc override func cancelOperation(_ sender: Any?) {
        closePanel()
    }

    // MARK: - Theme

    private func applyTheme(_ theme: AppTheme) {
        backgroundView.apply(theme: theme)

        closeButton.contentTintColor = theme.settingsTint
        closeButton.layer?.backgroundColor = theme.settingsChromeSurfaceColor.cgColor
        closeButton.layer?.borderWidth = 1
        closeButton.layer?.borderColor = theme.settingsSidebarBorderColor.cgColor

        settingsButton.font = theme.quickControlsButtonFont
        settingsButton.layer?.backgroundColor = theme.settingsAccentSoftFill.cgColor
        settingsButton.layer?.borderWidth = 1
        settingsButton.layer?.borderColor = theme.settingsSidebarBorderColor.cgColor
        settingsButton.image = settingsIcon
        settingsButton.contentTintColor = theme.settingsTint

        quitButton.font = theme.quickControlsButtonFont
        quitButton.layer?.backgroundColor = theme.settingsChromeSurfaceColor.cgColor
        quitButton.layer?.borderWidth = 1
        quitButton.layer?.borderColor = theme.settingsSidebarBorderColor.cgColor
        quitButton.image = quitIcon
        quitButton.contentTintColor = theme.closeTint

        let isDark = theme.preferredColorScheme == .dark
        toastView.layer?.backgroundColor = NSColor(white: isDark ? 0.12 : 0.08, alpha: 0.88).cgColor
        toastLabel.textColor = .white
        toastLabel.font = .systemFont(ofSize: 12, weight: .medium)
    }

    // MARK: - Tile Actions

    private func configureTileActions() {
        let actionMap: [TileID: Selector] = [
            .keepAwake: #selector(toggleKeepAwake),
            .hiddenFiles: #selector(toggleHiddenFiles),
            .fileExtensions: #selector(toggleFileExtensions),
            .keyLight: #selector(toggleKeyLight),
            .nightShift: #selector(toggleNightShift),
            .hideDock: #selector(toggleHideDock),
            .hideBar: #selector(toggleHideBar),
            .cleanKey: #selector(openCleanKey)
        ]

        for (id, selector) in actionMap {
            allTileButtons[id]?.target = self
            allTileButtons[id]?.action = selector
        }
    }

    private func makeTileRow(_ buttons: [NSView]) -> NSStackView {
        let row = NSStackView(views: buttons)
        row.orientation = .horizontal
        row.distribution = .fillEqually
        row.spacing = QuickControlsLayout.stackSpacing
        row.translatesAutoresizingMaskIntoConstraints = false
        return row
    }

    private func applyTileState(
        _ state: QuickControlsTileState,
        to button: FeatureTileButton,
        theme: AppTheme,
        symbolName: String? = nil,
        captionOverride: String? = nil
    ) {
        button.update(
            badgeText: state.badgeText,
            badgeStyle: state.badgeStyle,
            enabled: state.isEnabled,
            theme: theme,
            alternate: state.alternate,
            symbolName: symbolName,
            captionOverride: captionOverride
        )
    }
}
