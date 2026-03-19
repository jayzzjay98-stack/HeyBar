import XCTest
@testable import HeyBar

final class QuickControlsTileStateTests: XCTestCase {
    func testStandardOnStateUsesOnBadge() {
        XCTAssertEqual(
            QuickControlsTileState.standard(isOn: true, alternate: false),
            QuickControlsTileState(
                badgeText: "ON",
                badgeStyle: .on,
                isEnabled: true,
                alternate: false
            )
        )
    }

    func testStandardOffStatePreservesAlternateStyling() {
        XCTAssertEqual(
            QuickControlsTileState.standard(isOn: false, alternate: true),
            QuickControlsTileState(
                badgeText: "OFF",
                badgeStyle: .off,
                isEnabled: true,
                alternate: true
            )
        )
    }

    func testSupportedFeatureOnStateUsesEnabledBadge() {
        XCTAssertEqual(
            QuickControlsTileState.supportedFeature(isSupported: true, isOn: true, alternate: false),
            QuickControlsTileState(
                badgeText: "ON",
                badgeStyle: .on,
                isEnabled: true,
                alternate: false
            )
        )
    }

    func testUnsupportedFeatureUsesDisabledState() {
        XCTAssertEqual(
            QuickControlsTileState.supportedFeature(isSupported: false, isOn: true, alternate: true),
            QuickControlsTileState(
                badgeText: "N/A",
                badgeStyle: .disabled,
                isEnabled: false,
                alternate: true
            )
        )
    }
}
