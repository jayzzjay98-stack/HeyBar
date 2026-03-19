import Foundation

@MainActor
final class KeyLightController: ObservableObject {
    @Published private(set) var isSupported: Bool
    @Published private(set) var isEnabled: Bool
    private var isSyncingFromSystem = false

    @Published var brightness: Double {
        didSet {
            guard !isSyncingFromSystem else { return }
            guard brightness != oldValue else { return }

            let clamped = DisplayFeatureValue.clampedUnitInterval(brightness)
            if brightness != clamped {
                brightness = clamped
                return
            }

            defaults.set(clamped, forKey: Self.brightnessKey)
            guard isSupported, isEnabled else { return }
            _ = bridge.setBrightness(Float(clamped))
        }
    }

    @Published var autoBrightness: Bool {
        didSet {
            guard !isSyncingFromSystem else { return }
            guard autoBrightness != oldValue else { return }
            guard isSupported else { return }
            _ = bridge.setAutoBrightnessEnabled(autoBrightness)
        }
    }

    private let bridge: any KeyLightManaging
    private let defaults: UserDefaults

    private static let brightnessKey = "keyLight.brightness"

    init(
        bridge: any KeyLightManaging = KeyLightBridgeAdapter(),
        defaults: UserDefaults = .standard
    ) {
        self.bridge = bridge
        self.defaults = defaults

        let supported = bridge.isSupported()
        isSupported = supported

        let currentBrightness = supported ? Double(bridge.brightness()) : 0.6
        let storedBrightness = defaults.object(forKey: Self.brightnessKey) as? Double
        brightness = DisplayFeatureValue.clampedUnitInterval(storedBrightness ?? max(currentBrightness, 0.6))
        autoBrightness = supported ? bridge.isAutoBrightnessEnabled() : false
        isEnabled = supported ? bridge.brightness() > 0.01 : false
    }

    func refresh() {
        guard isSupported else {
            isEnabled = false
            autoBrightness = false
            return
        }

        isSyncingFromSystem = true
        defer { isSyncingFromSystem = false }

        let currentBrightness = Double(bridge.brightness())
        isEnabled = currentBrightness > 0.01
        if isEnabled {
            brightness = DisplayFeatureValue.clampedUnitInterval(currentBrightness)
        }
        autoBrightness = bridge.isAutoBrightnessEnabled()
    }

    func setEnabled(_ enabled: Bool) {
        guard isSupported else { return }
        let targetBrightness = enabled ? brightness : 0.0
        _ = bridge.setBrightness(Float(targetBrightness))
        refresh()
    }

    func toggle() {
        setEnabled(!isEnabled)
    }
}
