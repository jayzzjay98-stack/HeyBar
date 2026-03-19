import Foundation

@MainActor
final class ShortcutController: ObservableObject {
    @Published private(set) var lastError: String?

    private let hotKeyManager: HotKeyManaging
    private let store: ShortcutStore

    init(
        handler: @escaping (ShortcutAction) -> Void,
        hotKeyManager: HotKeyManaging? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.hotKeyManager = hotKeyManager ?? HotKeyManager(handler: handler)
        self.store = ShortcutStore(defaults: defaults)
        restoreSavedShortcuts()
    }

    func shortcut(for action: ShortcutAction) -> KeyboardShortcut? {
        store.loadShortcut(for: action)
    }

    func setShortcut(_ shortcut: KeyboardShortcut?, for action: ShortcutAction) {
        lastError = nil
        let currentShortcut = store.loadShortcut(for: action)

        guard currentShortcut != shortcut else {
            objectWillChange.send()
            return
        }

        guard let shortcut else {
            clearShortcut(for: action)
            objectWillChange.send()
            return
        }

        let duplicateShortcuts = duplicateShortcuts(for: shortcut, excluding: action)
        hotKeyManager.unregister(for: action)
        duplicateShortcuts.keys.forEach { hotKeyManager.unregister(for: $0) }

        switch hotKeyManager.register(shortcut, for: action) {
        case .success:
            store.persistShortcut(shortcut, for: action)
            duplicateShortcuts.keys.forEach { store.persistShortcut(nil, for: $0) }
            let clearedDuplicates = duplicateShortcuts.keys.map(\.rawValue).joined(separator: ", ")
            HeyBarDiagnostics.debug(
                HeyBarLog.shortcuts,
                "Registered shortcut for \(action.rawValue). Cleared duplicates: \(clearedDuplicates)"
            )
        case .failure(let message):
            lastError = restoreShortcutState(
                afterFailedRegistrationFor: action,
                currentShortcut: currentShortcut,
                duplicateShortcuts: duplicateShortcuts,
                baseMessage: message
            )
            HeyBarDiagnostics.error(HeyBarLog.shortcuts, lastError ?? message)
        }

        objectWillChange.send()
    }

    private func restoreSavedShortcuts() {
        ShortcutAction.allCases.forEach { action in
            guard let shortcut = store.loadShortcut(for: action) else { return }

            switch hotKeyManager.register(shortcut, for: action) {
            case .success:
                break
            case .failure:
                store.persistShortcut(nil, for: action)
                lastError = UserFacingMessages.savedShortcutCleared(for: action.title)
                HeyBarDiagnostics.error(HeyBarLog.shortcuts, lastError ?? "Shortcut restore failed.")
            }
        }
    }

    private func clearShortcut(for action: ShortcutAction) {
        hotKeyManager.unregister(for: action)
        store.persistShortcut(nil, for: action)
    }

    private func duplicateShortcuts(
        for shortcut: KeyboardShortcut,
        excluding action: ShortcutAction
    ) -> [ShortcutAction: KeyboardShortcut] {
        Dictionary(uniqueKeysWithValues: ShortcutAction.allCases.compactMap { otherAction in
            guard otherAction != action, store.loadShortcut(for: otherAction) == shortcut else {
                return nil
            }
            return (otherAction, shortcut)
        })
    }

    private func restoreShortcutState(
        afterFailedRegistrationFor action: ShortcutAction,
        currentShortcut: KeyboardShortcut?,
        duplicateShortcuts: [ShortcutAction: KeyboardShortcut],
        baseMessage: String
    ) -> String {
        var restoreFailures: [String] = []

        if let currentShortcut {
            switch hotKeyManager.register(currentShortcut, for: action) {
            case .success:
                break
            case .failure:
                store.persistShortcut(nil, for: action)
                restoreFailures.append(action.title)
            }
        }

        duplicateShortcuts.forEach { duplicateAction, duplicateShortcut in
            switch hotKeyManager.register(duplicateShortcut, for: duplicateAction) {
            case .success:
                break
            case .failure:
                store.persistShortcut(nil, for: duplicateAction)
                restoreFailures.append(duplicateAction.title)
            }
        }

        guard !restoreFailures.isEmpty else {
            return baseMessage
        }

        let restoredTitles = restoreFailures.joined(separator: ", ")
        return UserFacingMessages.shortcutRestoreFailed(baseMessage: baseMessage, restoredTitles: restoredTitles)
    }
}
