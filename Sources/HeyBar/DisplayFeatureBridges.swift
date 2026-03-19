import Foundation
import NightShiftBridge

protocol NightShiftManaging {
    func isSupported() -> Bool
    func isEnabled() -> Bool
    func strength() -> Float
    @discardableResult func setEnabled(_ enabled: Bool) -> Bool
    @discardableResult func setStrength(_ strength: Float) -> Bool
}

struct NightShiftBridgeAdapter: NightShiftManaging {
    func isSupported() -> Bool {
        HSBNightShiftIsSupported()
    }

    func isEnabled() -> Bool {
        HSBNightShiftIsEnabled()
    }

    func strength() -> Float {
        HSBNightShiftGetStrength()
    }

    func setEnabled(_ enabled: Bool) -> Bool {
        HSBNightShiftSetEnabled(enabled)
    }

    func setStrength(_ strength: Float) -> Bool {
        HSBNightShiftSetStrength(strength)
    }
}

protocol KeyLightManaging {
    func isSupported() -> Bool
    func brightness() -> Float
    func isAutoBrightnessEnabled() -> Bool
    @discardableResult func setBrightness(_ brightness: Float) -> Bool
    @discardableResult func setAutoBrightnessEnabled(_ enabled: Bool) -> Bool
}

struct KeyLightBridgeAdapter: KeyLightManaging {
    func isSupported() -> Bool {
        HSBKeyLightIsSupported()
    }

    func brightness() -> Float {
        HSBKeyLightGetBrightness()
    }

    func isAutoBrightnessEnabled() -> Bool {
        HSBKeyLightIsAutoBrightnessEnabled()
    }

    func setBrightness(_ brightness: Float) -> Bool {
        HSBKeyLightSetBrightness(brightness)
    }

    func setAutoBrightnessEnabled(_ enabled: Bool) -> Bool {
        HSBKeyLightSetAutoBrightnessEnabled(enabled)
    }
}

enum DisplayFeatureValue {
    static func clampedUnitInterval(_ value: Double, minimum: Double = 0.1) -> Double {
        min(max(value, minimum), 1.0)
    }
}
