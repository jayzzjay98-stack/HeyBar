import AppKit

enum QuickControlsLayout {
    static let panelSize = NSSize(width: 338, height: 490)
    static let panelInset: CGFloat = 14
    static let stackSpacing: CGFloat = 12
    static let edgePadding: CGFloat = 8
    static let tileHeight: CGFloat = 92
    static let footerButtonHeight: CGFloat = 34
    static let closeButtonSize: CGFloat = 36
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
    static let settingsButtonMinWidth: CGFloat = 112
    static let quitButtonMinWidth: CGFloat = 96
    // Animation durations
    static let panelShowDuration: TimeInterval = 0.28
    static let panelHideDuration: TimeInterval = 0.18
    static let tilePressDuration: TimeInterval = 0.08
    static let tileUpdateDuration: TimeInterval = 0.16
    static let toastFadeInDuration: TimeInterval = 0.18
    static let toastFadeOutDuration: TimeInterval = 0.28
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

        // Rebuild grid and resize panel BEFORE the panel becomes visible
        let panelSize = contentController.prepareForShow()
        panel.setContentSize(panelSize)

        let buttonFrame = buttonWindow.convertToScreen(button.frame)
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

        // Start above the final position so the panel drops down from the menu bar.
        panel.setFrameOrigin(NSPoint(x: panel.frame.origin.x, y: panel.frame.origin.y + 10))

        // Prepare a subtle scale-from-top using the content layer.
        if let layer = panel.contentView?.layer {
            panel.contentView?.wantsLayer = true
            // Anchor at top-center so scale originates from the menu-bar edge.
            let size = layer.bounds.size
            layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
            layer.position    = CGPoint(x: size.width / 2, y: size.height)
            layer.transform   = CATransform3DScale(CATransform3DIdentity, 0.94, 0.94, 1)
        }
    }

    private func animateOpen(to finalOrigin: NSPoint) {
        // Spring-like cubic bezier: fast departure, gentle settle.
        let spring = CAMediaTimingFunction(controlPoints: 0.22, 1.0, 0.36, 1.0)

        // Fade + slide via NSAnimationContext.
        NSAnimationContext.runAnimationGroup { context in
            context.duration = QuickControlsLayout.panelShowDuration
            context.timingFunction = spring
            panel.animator().alphaValue = 1
            panel.animator().setFrameOrigin(finalOrigin)
        } completionHandler: {
            Task { @MainActor in
                // Restore default anchor point so future layout is unaffected.
                if let layer = self.panel.contentView?.layer {
                    let size = layer.bounds.size
                    layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                    layer.position    = CGPoint(x: size.width / 2, y: size.height / 2)
                }
                self.isAnimating = false
            }
        }

        // Scale via Core Animation (runs alongside NSAnimationContext).
        if let layer = panel.contentView?.layer {
            let anim = CABasicAnimation(keyPath: "transform")
            anim.fromValue        = CATransform3DScale(CATransform3DIdentity, 0.94, 0.94, 1)
            anim.toValue          = CATransform3DIdentity
            anim.duration         = QuickControlsLayout.panelShowDuration
            anim.timingFunction   = spring
            anim.fillMode         = .forwards
            anim.isRemovedOnCompletion = false
            layer.add(anim, forKey: "openScale")
            layer.transform = CATransform3DIdentity
        }
    }

    private func animateClose() {
        isAnimating = true
        // Slide back up toward the menu bar while fading out.
        let finalOrigin = NSPoint(x: panel.frame.origin.x, y: panel.frame.origin.y + 8)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = QuickControlsLayout.panelHideDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
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
