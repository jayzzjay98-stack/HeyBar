import XCTest
@testable import HeyBar

@MainActor
final class ShortcutControllerTests: XCTestCase {
    func testFailedRegistrationKeepsExistingShortcut() {
        let defaults = makeDefaults()
        let manager = MockHotKeyManager()
        let controller = ShortcutController(handler: { _ in }, hotKeyManager: manager, defaults: defaults)
        let existing = KeyboardShortcut(keyCode: 1, modifiers: 2)
        let failing = KeyboardShortcut(keyCode: 3, modifiers: 4)

        controller.setShortcut(existing, for: .keepAwake)
        manager.results[RegistrationKey(shortcut: failing, action: .keepAwake)] = .failure("Shortcut registration failed.")

        controller.setShortcut(failing, for: .keepAwake)

        XCTAssertEqual(controller.shortcut(for: .keepAwake), existing)
        XCTAssertEqual(controller.lastError, "Shortcut registration failed.")
    }

    func testSuccessfulRegistrationClearsDuplicateShortcut() {
        let defaults = makeDefaults()
        let manager = MockHotKeyManager()
        let controller = ShortcutController(handler: { _ in }, hotKeyManager: manager, defaults: defaults)
        let shortcut = KeyboardShortcut(keyCode: 12, modifiers: 34)

        controller.setShortcut(shortcut, for: .keepAwake)
        controller.setShortcut(shortcut, for: .hideDock)

        XCTAssertNil(controller.shortcut(for: .keepAwake))
        XCTAssertEqual(controller.shortcut(for: .hideDock), shortcut)
        XCTAssertNil(controller.lastError)
    }

    func testUnavailableSavedShortcutIsClearedDuringInitialization() {
        let defaults = makeDefaults()
        let unavailable = KeyboardShortcut(keyCode: 7, modifiers: 8)
        let data = try! JSONEncoder().encode(unavailable)
        defaults.set(data, forKey: "shortcut.keepAwake")

        let manager = MockHotKeyManager()
        manager.results[RegistrationKey(shortcut: unavailable, action: .keepAwake)] = .failure("Shortcut registration failed.")

        let controller = ShortcutController(handler: { _ in }, hotKeyManager: manager, defaults: defaults)

        XCTAssertNil(controller.shortcut(for: .keepAwake))
        XCTAssertEqual(controller.lastError, "Saved shortcut for Keep Awake was unavailable and has been cleared.")
    }

    func testFailedRegistrationClearsCurrentShortcutWhenRollbackFails() {
        let defaults = makeDefaults()
        let manager = MockHotKeyManager()
        let controller = ShortcutController(handler: { _ in }, hotKeyManager: manager, defaults: defaults)
        let existing = KeyboardShortcut(keyCode: 1, modifiers: 2)
        let failing = KeyboardShortcut(keyCode: 3, modifiers: 4)

        controller.setShortcut(existing, for: .keepAwake)
        manager.results[RegistrationKey(shortcut: failing, action: .keepAwake)] = .failure("Shortcut registration failed.")
        manager.results[RegistrationKey(shortcut: existing, action: .keepAwake)] = .failure("Restore failed.")

        controller.setShortcut(failing, for: .keepAwake)

        XCTAssertNil(controller.shortcut(for: .keepAwake))
        XCTAssertEqual(
            controller.lastError,
            "Shortcut registration failed. Existing shortcuts for Keep Awake could not be restored and were cleared."
        )
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "ShortcutControllerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

private struct RegistrationKey: Hashable {
    let shortcut: KeyboardShortcut
    let action: ShortcutAction
}

private final class MockHotKeyManager: HotKeyManaging {
    var results: [RegistrationKey: HotKeyRegistrationResult] = [:]

    func register(_ shortcut: KeyboardShortcut, for action: ShortcutAction) -> HotKeyRegistrationResult {
        results[RegistrationKey(shortcut: shortcut, action: action)] ?? .success
    }

    func unregister(for action: ShortcutAction) {}
}
