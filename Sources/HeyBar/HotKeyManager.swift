import Carbon
import Foundation

enum HotKeyRegistrationResult: Equatable {
    case success
    case failure(String)
}

protocol HotKeyManaging {
    func register(_ shortcut: KeyboardShortcut, for action: ShortcutAction) -> HotKeyRegistrationResult
    func unregister(for action: ShortcutAction)
}

// Indirection box retained by Carbon's event handler; holds a weak reference
// to the manager to avoid a retain cycle and dangling pointer.
private final class HotKeyHandlerBox {
    weak var manager: HotKeyManager?
    init(_ manager: HotKeyManager) { self.manager = manager }
}

final class HotKeyManager: HotKeyManaging {
    private enum Constants {
        static let signature = "HEYB"
    }

    private var handlerRef: EventHandlerRef?
    private var registrations: [ShortcutAction: EventHotKeyRef] = [:]
    private let handler: (ShortcutAction) -> Void
    // Retained here so we can release it in deinit after handler removal.
    private var handlerBox: Unmanaged<HotKeyHandlerBox>?

    init(handler: @escaping (ShortcutAction) -> Void) {
        self.handler = handler
        installHandlerIfNeeded()
    }

    deinit {
        registrations.values.forEach { UnregisterEventHotKey($0) }
        if let handlerRef {
            RemoveEventHandler(handlerRef)
        }
        // Safe to release after RemoveEventHandler — Carbon will not invoke the callback again.
        handlerBox?.release()
    }

    func register(_ shortcut: KeyboardShortcut, for action: ShortcutAction) -> HotKeyRegistrationResult {
        unregister(for: action)

        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: fourCharCode(Constants.signature), id: action.hotKeyID)
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr, let hotKeyRef {
            registrations[action] = hotKeyRef
            return .success
        }

        HeyBarDiagnostics.error(HeyBarLog.shortcuts, "Failed to register shortcut for \(action.rawValue) with status \(status)")
        return .failure(UserFacingMessages.shortcutUnavailable)
    }

    func unregister(for action: ShortcutAction) {
        guard let ref = registrations.removeValue(forKey: action) else { return }
        UnregisterEventHotKey(ref)
    }

    private func installHandlerIfNeeded() {
        guard handlerRef == nil else { return }
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        // Pass a retained box as the userData pointer. The box holds a weak reference
        // so the Carbon callback receives nil safely if the manager is freed.
        let box = HotKeyHandlerBox(self)
        let retained = Unmanaged.passRetained(box)
        handlerBox = retained

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard let userData, let event else { return noErr }
                let box = Unmanaged<HotKeyHandlerBox>.fromOpaque(userData).takeUnretainedValue()
                return box.manager?.handleHotKeyEvent(event) ?? noErr
            },
            1,
            &eventSpec,
            retained.toOpaque(),
            &handlerRef
        )
    }

    private func handleHotKeyEvent(_ event: EventRef) -> OSStatus {
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard status == noErr else { return status }
        guard let action = ShortcutAction.allCases.first(where: { $0.hotKeyID == hotKeyID.id }) else {
            return noErr
        }

        handler(action)
        return noErr
    }

    private func fourCharCode(_ string: String) -> FourCharCode {
        string.utf8.reduce(0) { ($0 << 8) + FourCharCode($1) }
    }
}
