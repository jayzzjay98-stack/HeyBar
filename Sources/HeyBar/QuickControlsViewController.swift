import AppKit

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

    private let keepAwakeButton = FeatureTileButton(
        title: "Keep Awake",
        symbolName: "sparkles.tv",
        caption: "Session"
    )
    private let hiddenFilesButton = FeatureTileButton(
        title: "Hidden Files",
        symbolName: "folder.badge.questionmark",
        caption: "Finder"
    )
    private let fileExtensionsButton = FeatureTileButton(
        title: "File Extensions",
        symbolName: "doc.badge.gearshape",
        caption: "Finder"
    )
    private let keyLightButton = FeatureTileButton(
        title: "Key Light",
        symbolName: "keyboard",
        caption: "Display"
    )
    private let nightShiftButton = FeatureTileButton(
        title: "Night Shift",
        symbolName: "moon.stars.fill",
        caption: "Display"
    )
    private let hideDockButton = FeatureTileButton(
        title: "Hide Dock",
        symbolName: "dock.rectangle",
        caption: "Automation"
    )
    private let hideBarButton = FeatureTileButton(
        title: "Hide Bar",
        symbolName: "menubar.rectangle",
        caption: "Automation"
    )
    private let cleanKeyButton = FeatureTileButton(
        title: "CleanKey",
        symbolName: "sparkles",
        caption: "Apps"
    )

    init(model: AppModel, openSettings: @escaping () -> Void) {
        self.model = model
        self.openSettings = openSettings
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView(frame: NSRect(origin: .zero, size: QuickControlsLayout.panelSize))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor

        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.wantsLayer = true

        setupCloseButton()
        configureTileActions()
        setupFooterButtons()
        setupToastView()

        let tileRow1 = makeTileRow([keepAwakeButton, hiddenFilesButton])
        let tileRow2 = makeTileRow([fileExtensionsButton, keyLightButton])
        let tileRow3 = makeTileRow([nightShiftButton, hideDockButton])
        let tileRow4 = makeTileRow([hideBarButton, cleanKeyButton])
        let tileRows = [tileRow1, tileRow2, tileRow3, tileRow4]

        let topBar = makeTopBar()
        let footerBar = makeFooterBar()
        let contentStack = makeContentStack(topBar: topBar, tileRows: tileRows, footerBar: footerBar)

        backgroundView.addSubview(contentStack)
        view.addSubview(backgroundView)
        view.addSubview(toastView)

        activateLayoutConstraints(
            contentStack: contentStack,
            topBar: topBar,
            footerBar: footerBar,
            tileRows: tileRows
        )

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
        closeButton.layer?.cornerRadius = 13
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

        quitButton.translatesAutoresizingMaskIntoConstraints = false
        quitButton.isBordered = false
        quitButton.wantsLayer = true
        quitButton.layer?.cornerRadius = 10
        quitButton.imagePosition = .imageLeading
        quitButton.imageHugsTitle = true
        quitButton.alignment = .center
        quitButton.target = self
        quitButton.action = #selector(quitApp)
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

    private func makeContentStack(topBar: NSStackView, tileRows: [NSStackView], footerBar: NSStackView) -> NSStackView {
        let stack = NSStackView(views: [topBar] + tileRows + [footerBar])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = QuickControlsLayout.stackSpacing
        return stack
    }

    private func activateLayoutConstraints(
        contentStack: NSStackView,
        topBar: NSStackView,
        footerBar: NSStackView,
        tileRows: [NSStackView]
    ) {
        var constraints: [NSLayoutConstraint] = [
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

        let allTileButtons = [keepAwakeButton, hiddenFilesButton, fileExtensionsButton,
                              keyLightButton, nightShiftButton, hideDockButton,
                              hideBarButton, cleanKeyButton]
        constraints += tileRows.map { $0.widthAnchor.constraint(equalTo: contentStack.widthAnchor) }
        constraints += allTileButtons.map { $0.heightAnchor.constraint(equalToConstant: QuickControlsLayout.tileHeight) }

        NSLayoutConstraint.activate(constraints)
    }

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

    func refresh() {
        let theme = model.selectedTheme
        applyTheme(theme)

        let keepAwakeOn = model.keepAwake.isEnabled
        let keepAwakeBadge = keepAwakeCountdownText() ?? (keepAwakeOn ? "ON" : "OFF")
        applyTileState(
            QuickControlsTileState(badgeText: keepAwakeBadge, badgeStyle: keepAwakeOn ? .on : .off, isEnabled: true, alternate: false),
            to: keepAwakeButton,
            theme: theme,
            symbolName: keepAwakeOn ? "bolt.fill" : "sparkles.tv",
            captionOverride: shortcutLabel(for: .keepAwake)
        )

        let hiddenOn = model.hiddenFiles.isEnabled
        applyTileState(.standard(isOn: hiddenOn, alternate: true), to: hiddenFilesButton, theme: theme,
            symbolName: hiddenOn ? "folder.fill.badge.questionmark" : "folder.badge.questionmark",
            captionOverride: shortcutLabel(for: .showHiddenFiles)
        )

        let extOn = model.fileExtensions.isEnabled
        applyTileState(.standard(isOn: extOn, alternate: true), to: fileExtensionsButton, theme: theme,
            captionOverride: shortcutLabel(for: .showFileExtensions)
        )

        applyTileState(
            .supportedFeature(isSupported: model.keyLight.isSupported, isOn: model.keyLight.isEnabled, alternate: false),
            to: keyLightButton,
            theme: theme,
            captionOverride: shortcutLabel(for: .keyLight)
        )

        let nightOn = model.nightShift.isEnabled
        applyTileState(
            .supportedFeature(isSupported: model.nightShift.isSupported, isOn: nightOn, alternate: false),
            to: nightShiftButton,
            theme: theme,
            symbolName: nightOn ? "moon.stars.fill" : "moon.stars",
            captionOverride: shortcutLabel(for: .nightShift)
        )

        let dockOn = model.hideDock.isEnabled
        applyTileState(.standard(isOn: dockOn, alternate: true), to: hideDockButton, theme: theme,
            symbolName: dockOn ? "dock.arrow.down.rectangle" : "dock.rectangle",
            captionOverride: shortcutLabel(for: .hideDock)
        )

        let barOn = model.hideBar.isEnabled
        applyTileState(.standard(isOn: barOn, alternate: false), to: hideBarButton, theme: theme,
            symbolName: barOn ? "menubar.arrow.up.rectangle" : "menubar.rectangle",
            captionOverride: shortcutLabel(for: .hideBar)
        )

        applyTileState(
            QuickControlsTileState(
                badgeText: model.cleanKey.isCleaning ? model.cleanKey.remainingBadgeText : "START",
                badgeStyle: model.cleanKey.isCleaning ? .on : .off,
                isEnabled: true,
                alternate: true
            ),
            to: cleanKeyButton,
            theme: theme,
            symbolName: model.cleanKey.isCleaning ? "lock.fill" : "sparkles",
            captionOverride: shortcutLabel(for: .cleanKey) ?? "Cleaning"
        )

        updateTooltips()
    }

    private func updateTooltips() {
        keyLightButton.toolTip = model.keyLight.isSupported
            ? "Toggle keyboard backlight"
            : "Key Light is unavailable on this Mac"
        nightShiftButton.toolTip = model.nightShift.isSupported
            ? "Toggle Night Shift"
            : "Night Shift is unavailable on this Mac"
        hideDockButton.toolTip = model.hideDock.lastError == nil
            ? "Toggle Dock auto-hide"
            : "Automation permission may be required"
        hideBarButton.toolTip = model.hideBar.lastError == nil
            ? "Toggle menu bar auto-hide"
            : "Automation permission may be required"
        cleanKeyButton.toolTip = model.cleanKey.isCleaning
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

    private func showToast(_ message: String) {
        toastLabel.stringValue = message
        toastView.layer?.removeAllAnimations()

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
        settingsButton.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Settings")
        settingsButton.contentTintColor = theme.settingsTint

        quitButton.font = theme.quickControlsButtonFont
        quitButton.layer?.backgroundColor = theme.settingsChromeSurfaceColor.cgColor
        quitButton.layer?.borderWidth = 1
        quitButton.layer?.borderColor = theme.settingsSidebarBorderColor.cgColor
        quitButton.image = NSImage(systemSymbolName: "power", accessibilityDescription: "Quit")
        quitButton.contentTintColor = theme.closeTint

        toastView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.72).cgColor
        toastLabel.textColor = .white
        toastLabel.font = .systemFont(ofSize: 12, weight: .medium)
    }

    private func configureTileActions() {
        setAction(#selector(toggleKeepAwake), for: keepAwakeButton)
        setAction(#selector(toggleHiddenFiles), for: hiddenFilesButton)
        setAction(#selector(toggleFileExtensions), for: fileExtensionsButton)
        setAction(#selector(toggleKeyLight), for: keyLightButton)
        setAction(#selector(toggleNightShift), for: nightShiftButton)
        setAction(#selector(toggleHideDock), for: hideDockButton)
        setAction(#selector(toggleHideBar), for: hideBarButton)
        setAction(#selector(openCleanKey), for: cleanKeyButton)
    }

    private func setAction(_ action: Selector, for button: FeatureTileButton) {
        button.target = self
        button.action = action
    }

    private func makeTileRow(_ buttons: [FeatureTileButton]) -> NSStackView {
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
