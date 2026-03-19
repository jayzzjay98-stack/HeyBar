import Foundation

final class ShortcutStore {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadShortcut(for action: ShortcutAction) -> KeyboardShortcut? {
        guard let data = defaults.data(forKey: action.storageKey) else { return nil }
        return try? decoder.decode(KeyboardShortcut.self, from: data)
    }

    func persistShortcut(_ shortcut: KeyboardShortcut?, for action: ShortcutAction) {
        guard let shortcut else {
            defaults.removeObject(forKey: action.storageKey)
            return
        }

        if let data = try? encoder.encode(shortcut) {
            defaults.set(data, forKey: action.storageKey)
        }
    }
}
