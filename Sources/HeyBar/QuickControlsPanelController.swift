import AppKit

enum QuickControlsLayout {
    static let panelSize = NSSize(width: 338, height: 490)
    static let panelInset: CGFloat = 14
    static let stackSpacing: CGFloat = 12
    static let edgePadding: CGFloat = 8
    static let tileHeight: CGFloat = 92
    static let footerButtonHeight: CGFloat = 34
    static let closeButtonSize: CGFloat = 26
    static let logoBadgeSize: CGFloat = 36
    static let featureTileCornerRadius: CGFloat = 18
    static let backgroundCornerRadius: CGFloat = 22
    static let headerIconInsetLeading: CGFloat = 14
    static let headerIconInsetTop: CGFloat = 12
    static let badgeInsetTrailing: CGFloat = 10
    static let badgeInsetTop: CGFloat = 10
    static let titleInsetHorizontal: CGFloat = 12
    static let titleInsetBottom: CGFloat = 12
    static let settingsButtonHeight: CGFloat = 34
}

@MainActor
final class QuickControlsPanelController {
    private let panel: QuickControlsPanel
    private let contentController: QuickControlsViewController
    private var globalMonitor: Any?
    private var isAnimating = false

    init(model: AppModel, openSettings: @escaping () -> Void) {
        contentController = QuickControlsViewController(
            model: model,
            openSettings: openSettings
        )

        panel = QuickControlsPanel(
            contentRect: NSRect(origin: .zero, size: QuickControlsLayout.panelSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = contentController
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.transient, .moveToActiveSpace]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = false

        contentController.onClose = { [weak self] in
            self?.close()
        }
    }

    func toggle(relativeTo button: NSStatusBarButton) {
        if panel.isVisible {
            close()
            return
        }
        show(relativeTo: button)
    }

    func close() {
        guard panel.isVisible, !isAnimating else { return }
        stopMonitor()
        animateClose()
    }

    private func show(relativeTo button: NSStatusBarButton) {
        guard let buttonWindow = button.window else { return }

        contentController.refresh()

        let buttonFrame = buttonWindow.convertToScreen(button.frame)
        let panelSize = panel.frame.size
        let screen = buttonWindow.screen ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero

        var originX = buttonFrame.maxX - panelSize.width
        originX = min(
            max(originX, visibleFrame.minX + QuickControlsLayout.edgePadding),
            visibleFrame.maxX - panelSize.width - QuickControlsLayout.edgePadding
        )
        let originY = max(
            visibleFrame.minY + QuickControlsLayout.edgePadding,
            buttonFrame.minY - panelSize.height - QuickControlsLayout.edgePadding
        )

        panel.setFrameOrigin(NSPoint(x: originX, y: originY))
        NSApp.activate(ignoringOtherApps: true)
        prepareOpenAnimation()
        panel.makeKeyAndOrderFront(nil)
        animateOpen(to: NSPoint(x: originX, y: originY))
        startMonitor()
    }

    private func prepareOpenAnimation() {
        isAnimating = true
        panel.alphaValue = 0
        panel.setFrameOrigin(NSPoint(x: panel.frame.origin.x, y: panel.frame.origin.y - 10))
    }

    private func animateOpen(to finalOrigin: NSPoint) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.14
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
            panel.animator().setFrameOrigin(finalOrigin)
        } completionHandler: {
            Task { @MainActor in
                self.isAnimating = false
            }
        }
    }

    private func animateClose() {
        isAnimating = true
        let finalOrigin = NSPoint(x: panel.frame.origin.x, y: panel.frame.origin.y - 8)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().alphaValue = 0
            panel.animator().setFrameOrigin(finalOrigin)
        } completionHandler: {
            Task { @MainActor in
                self.panel.orderOut(nil)
                self.panel.alphaValue = 1
                self.isAnimating = false
            }
        }
    }

    private func startMonitor() {
        stopMonitor()
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] _ in
            Task { @MainActor in
                self?.close()
            }
        }
    }

    private func stopMonitor() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
    }
}

private final class QuickControlsPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
