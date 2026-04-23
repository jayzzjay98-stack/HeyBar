import AppKit
import XCTest
@testable import HeyBar

final class StatusBarBehaviorTests: XCTestCase {
    func testLeftClickTogglesQuickPanel() {
        let event = NSEvent.mouseEvent(
            with: .leftMouseUp,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 0
        )

        XCTAssertEqual(StatusBarBehavior.action(for: event), .toggleQuickPanel)
    }

    func testControlLeftClickTogglesHiddenMode() {
        let event = NSEvent.mouseEvent(
            with: .leftMouseUp,
            location: .zero,
            modifierFlags: [.control],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 0
        )

        XCTAssertEqual(StatusBarBehavior.action(for: event), .toggleHiddenMode)
    }

    func testRevealHiddenModeOnlyInsideMenuBarBand() {
        let screenFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)

        XCTAssertTrue(
            StatusBarBehavior.shouldRevealHiddenMode(
                mouseLocation: NSPoint(x: 500, y: 878),
                screenFrames: [screenFrame],
                fallbackScreenFrame: nil,
                menuBarThickness: 22
            )
        )
        XCTAssertFalse(
            StatusBarBehavior.shouldRevealHiddenMode(
                mouseLocation: NSPoint(x: 500, y: 860),
                screenFrames: [screenFrame],
                fallbackScreenFrame: nil,
                menuBarThickness: 22
            )
        )
    }

    func testHiddenModeStorePersistsValue() {
        let suiteName = "StatusBarBehaviorTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = StatusBarHiddenModeStore(defaults: defaults, key: "statusBar.hidden")

        store.save(true)

        XCTAssertTrue(store.load())
    }

    func testMenuBarIconStyleStoreDefaultsToBar() {
        let suiteName = "StatusBarBehaviorTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = MenuBarIconStyleStore(defaults: defaults, key: "statusBar.icon")

        XCTAssertEqual(store.load(), .bar)
    }

    func testMenuBarIconStyleStorePersistsValue() {
        let suiteName = "StatusBarBehaviorTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = MenuBarIconStyleStore(defaults: defaults, key: "statusBar.icon")

        store.save(.spark)

        XCTAssertEqual(store.load(), .spark)
    }
}
