struct QuickControlsTileState: Equatable {
    let badgeText: String
    let badgeStyle: FeatureTileButton.BadgeStyle
    let isEnabled: Bool
    let alternate: Bool

    static func standard(isOn: Bool, alternate: Bool) -> QuickControlsTileState {
        QuickControlsTileState(
            badgeText: isOn ? "ON" : "OFF",
            badgeStyle: isOn ? .on : .off,
            isEnabled: true,
            alternate: alternate
        )
    }

    static func supportedFeature(isSupported: Bool, isOn: Bool, alternate: Bool) -> QuickControlsTileState {
        QuickControlsTileState(
            badgeText: isSupported ? (isOn ? "ON" : "OFF") : "N/A",
            badgeStyle: isSupported ? (isOn ? .on : .off) : .disabled,
            isEnabled: isSupported,
            alternate: alternate
        )
    }
}
