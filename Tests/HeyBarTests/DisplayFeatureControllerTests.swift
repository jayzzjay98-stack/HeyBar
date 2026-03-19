import XCTest
@testable import HeyBar

@MainActor
final class DisplayFeatureControllerTests: XCTestCase {
    func testNightShiftSetEnabledAppliesStoredStrength() {
        let defaults = makeDefaults(prefix: "NightShift")
        let bridge = MockNightShiftBridge()
        bridge.supported = true
        bridge.enabled = false
        bridge.currentStrength = 0.35

        let controller = NightShiftController(bridge: bridge, defaults: defaults)
        controller.strength = 0.8

        controller.setEnabled(true)

        XCTAssertEqual(bridge.setEnabledCalls, [true])
        XCTAssertEqual(Double(bridge.setStrengthCalls.last ?? -1), 0.8, accuracy: 0.0001)
    }

    func testNightShiftStrengthClampsAndPersists() {
        let defaults = makeDefaults(prefix: "NightShift")
        let bridge = MockNightShiftBridge()
        bridge.supported = true
        bridge.enabled = true
        bridge.currentStrength = 0.4

        let controller = NightShiftController(bridge: bridge, defaults: defaults)
        controller.strength = 4.0

        XCTAssertEqual(controller.strength, 1.0, accuracy: 0.0001)
        XCTAssertEqual(defaults.double(forKey: "nightShift.strength"), 1.0, accuracy: 0.0001)
        XCTAssertEqual(Double(bridge.setStrengthCalls.last ?? -1), 1.0, accuracy: 0.0001)
    }

    func testKeyLightSetEnabledFalseSetsZeroBrightness() {
        let defaults = makeDefaults(prefix: "KeyLight")
        let bridge = MockKeyLightBridge()
        bridge.supported = true
        bridge.currentBrightness = 0.7
        bridge.autoBrightnessEnabled = false

        let controller = KeyLightController(bridge: bridge, defaults: defaults)
        controller.setEnabled(false)

        XCTAssertEqual(Double(bridge.setBrightnessCalls.first ?? -1), 0.0, accuracy: 0.0001)
        XCTAssertFalse(controller.isEnabled)
    }

    func testKeyLightRefreshDoesNotWriteBackBrightness() {
        let defaults = makeDefaults(prefix: "KeyLight")
        let bridge = MockKeyLightBridge()
        bridge.supported = true
        bridge.currentBrightness = 0.55
        bridge.autoBrightnessEnabled = true

        let controller = KeyLightController(bridge: bridge, defaults: defaults)
        bridge.setBrightnessCalls.removeAll()

        controller.refresh()

        XCTAssertTrue(controller.isEnabled)
        XCTAssertEqual(controller.brightness, 0.55, accuracy: 0.0001)
        XCTAssertTrue(controller.autoBrightness)
        XCTAssertTrue(bridge.setBrightnessCalls.isEmpty)
    }

    private func makeDefaults(prefix: String) -> UserDefaults {
        let suiteName = "\(prefix).DisplayFeatureControllerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
