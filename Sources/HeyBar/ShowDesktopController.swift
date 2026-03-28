import AppKit

@MainActor
final class ShowDesktopController: ObservableObject {
    @Published private(set) var isEnabled = false
    private var coverWindows: [NSWindow] = []

    func toggle() {
        isEnabled ? restore() : show()
    }

    private func show() {
        for screen in NSScreen.screens {
            let window = makeCoverWindow(for: screen)
            window.orderFront(nil)
            coverWindows.append(window)
        }
        isEnabled = true
    }

    private func restore() {
        coverWindows.forEach { $0.close() }
        coverWindows.removeAll()
        isEnabled = false
    }

    private func makeCoverWindow(for screen: NSScreen) -> NSWindow {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        // Desktop icons sit at desktopWindow + 20; place this window just above them
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 21)
        window.isOpaque = true
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        let imageView = NSImageView(frame: NSRect(origin: .zero, size: screen.frame.size))
        imageView.imageScaling = .scaleAxesIndependently
        if let url = NSWorkspace.shared.desktopImageURL(for: screen),
           let img = NSImage(contentsOf: url) {
            imageView.image = img
        } else {
            imageView.image = nil
            window.backgroundColor = .black
        }
        window.contentView = imageView
        window.setFrame(screen.frame, display: false)
        return window
    }
}
