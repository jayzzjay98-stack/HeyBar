import Foundation

@MainActor
final class NightShiftController: ObservableObject {
    @Published private(set) var isSupported: Bool
    @Published private(set) var isEnabled: Bool
    @Published var strength: Double {
        didSet {
            let clamped = DisplayFeatureValue.clampedUnitInterval(strength)
            if strength != clamped {
                strength = clamped
                return
            }

            defaults.set(clamped, forKey: Self.strengthKey)
            guard isSupported, isEnabled else { return }
            _ = bridge.setStrength(Float(clamped))
        }
    }

    private let bridge: any NightShiftManaging
    private let defaults: UserDefaults

    private static let strengthKey = "nightShift.strength"

    init(
        bridge: any NightShiftManaging = NightShiftBridgeAdapter(),
        defaults: UserDefaults = .standard
    ) {
        self.bridge = bridge
        self.defaults = defaults

        let supported = bridge.isSupported()
        isSupported = supported
        isEnabled = supported ? bridge.isEnabled() : false

        let storedStrength = defaults.object(forKey: Self.strengthKey) as? Double
        let currentStrength = supported ? Double(bridge.strength()) : 0.5
        strength = DisplayFeatureValue.clampedUnitInterval(storedStrength ?? currentStrength)
    }

    func refresh() {
        guard isSupported else {
            isEnabled = false
            return
        }

        isEnabled = bridge.isEnabled()
        strength = DisplayFeatureValue.clampedUnitInterval(Double(bridge.strength()))
    }

    func setEnabled(_ enabled: Bool) {
        guard isSupported else { return }
        _ = bridge.setEnabled(enabled)
        if enabled {
            _ = bridge.setStrength(Float(strength))
        }
        refresh()
    }

    func toggle() {
        setEnabled(!isEnabled)
    }
}
