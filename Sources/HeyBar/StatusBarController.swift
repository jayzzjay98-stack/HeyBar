import AppKit
import Combine

@MainActor
final class StatusBarController {
    private let mainItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let quickPanel: QuickControlsPanelController
    private let hiddenModeStore: StatusBarHiddenModeStore
    private var isHidden = false
    private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

    init(model: AppModel, settingsHandler: @escaping () -> Void) {
        hiddenModeStore = StatusBarHiddenModeStore()
        quickPanel = QuickControlsPanelController(model: model, openSettings: settingsHandler)
        configureButton()

        model.keepAwake.$isEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in
                self?.updateStatusBarIcon(keepAwakeOn: isEnabled)
            }
            .store(in: &cancellables)

        let wasHidden = hiddenModeStore.load()
        if wasHidden { setHiddenMode(true) }

        showOnboardingIfNeeded()
    }

    func invalidate() {
        cancellables.removeAll()
        quickPanel.close()
        stopMonitor()
        NSStatusBar.system.removeStatusItem(mainItem)
    }

    func presentQuickPanelForCapture() {
        guard let button = mainItem.button else { return }
        quickPanel.toggle(relativeTo: button)
    }

    func setHiddenMode(_ enabled: Bool) {
        isHidden = enabled
        mainItem.length = enabled ? 10_000 : NSStatusItem.variableLength
        hiddenModeStore.save(enabled)
        enabled ? startMonitor() : stopMonitor()
        HeyBarDiagnostics.debug(HeyBarLog.app, "Hidden mode set to \(enabled)")
    }

    private func startMonitor() {
        guard eventMonitor == nil else { return }
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .rightMouseDown) { [weak self] _ in
            guard let self else { return }
            let shouldReveal = StatusBarBehavior.shouldRevealHiddenMode(
                mouseLocation: NSEvent.mouseLocation,
                screenFrames: NSScreen.screens.map(\.frame),
                fallbackScreenFrame: NSScreen.main?.frame,
                menuBarThickness: NSStatusBar.system.thickness
            )
            guard shouldReveal else { return }
            Task { @MainActor in self.setHiddenMode(false) }
        }
    }

    private func stopMonitor() {
        if let m = eventMonitor { NSEvent.removeMonitor(m); eventMonitor = nil }
    }

    private func configureButton() {
        guard let button = mainItem.button else { return }
        button.attributedTitle = NSAttributedString(
            string: "|",
            attributes: [
                .font: NSFont.systemFont(ofSize: 12, weight: .light),
                .foregroundColor: NSColor.labelColor
            ]
        )
        button.target = self
        button.action = #selector(handleClick)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp, .otherMouseUp])
    }

    private func updateStatusBarIcon(keepAwakeOn: Bool) {
        guard let button = mainItem.button else { return }
        if keepAwakeOn {
            let img = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: "HeyBar — Keep Awake Active")
            img?.isTemplate = true
            button.image = img
            button.imageScaling = .scaleProportionallyDown
            button.attributedTitle = NSAttributedString(string: "")
        } else {
            button.image = nil
            button.attributedTitle = NSAttributedString(
                string: "|",
                attributes: [
                    .font: NSFont.systemFont(ofSize: 12, weight: .light),
                    .foregroundColor: NSColor.labelColor
                ]
            )
        }
    }

    private func showOnboardingIfNeeded() {
        let key = "heybar.onboardingShown"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.showOnboardingPopover()
        }
    }

    private func showOnboardingPopover() {
        guard let button = mainItem.button else { return }

        let popover = NSPopover()
        popover.behavior = .transient

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 290, height: 70))

        let label = NSTextField(wrappingLabelWithString: "Click to open Quick Controls.\nRight-click to hide the icon — right-click the menu bar edge to reveal it again.")
        label.font = .systemFont(ofSize: 12.5)
        label.textColor = .labelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14)
        ])

        let vc = NSViewController()
        vc.view = container
        popover.contentViewController = vc
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            popover.close()
        }
    }

    @objc private func handleClick(_ sender: Any?) {
        switch StatusBarBehavior.action(for: NSApp.currentEvent) {
        case .toggleHiddenMode:
            quickPanel.close()
            setHiddenMode(!isHidden)
        case .toggleQuickPanel:
            guard let button = mainItem.button else { return }
            quickPanel.toggle(relativeTo: button)
        }
    }
}
