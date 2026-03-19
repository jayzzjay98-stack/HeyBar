import AppKit
import Carbon
import SwiftUI

struct ShortcutRecorderField: NSViewRepresentable {
    @Binding var shortcut: KeyboardShortcut?

    func makeNSView(context: Context) -> ShortcutRecorderButton {
        let button = ShortcutRecorderButton()
        button.onShortcutChange = { newShortcut in
            shortcut = newShortcut
        }
        button.shortcut = shortcut
        return button
    }

    func updateNSView(_ nsView: ShortcutRecorderButton, context: Context) {
        nsView.shortcut = shortcut
    }
}

final class ShortcutRecorderButton: NSButton {
    var onShortcutChange: ((KeyboardShortcut?) -> Void)?
    var shortcut: KeyboardShortcut? {
        didSet { updateTitle() }
    }

    private var isRecording = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        isBordered = false
        bezelStyle = .regularSquare
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        font = .monospacedSystemFont(ofSize: 12, weight: .semibold)
        target = self
        action = #selector(beginRecording)
        setButtonType(.momentaryChange)
        updateTitle()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    @objc private func beginRecording() {
        isRecording = true
        window?.makeFirstResponder(self)
        updateTitle()
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if isRecording {
            isRecording = false
            updateTitle()
        }
        return result
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        if event.keyCode == UInt16(kVK_Escape) {
            isRecording = false
            updateTitle()
            return
        }

        guard let captured = KeyboardShortcut.from(event: event) else {
            NSSound.beep()
            return
        }

        shortcut = captured
        onShortcutChange?(captured)
        isRecording = false
        updateTitle()
    }

    private func updateTitle() {
        if isRecording {
            title = "Type Shortcut"
        } else {
            title = shortcut?.displayString ?? "Record Shortcut"
        }
    }
}
