import AppKit

final class FeatureTileButton: NSButton {
    enum BadgeStyle: Equatable {
        case on
        case off
        case disabled
        case comingSoon
    }

    private let gradientLayer = CAGradientLayer()
    private let borderLayer = CALayer()
    private let iconBadgeView = NSView()
    private let titleField = NSTextField(labelWithString: "")
    private let captionField = NSTextField(labelWithString: "")
    private let badgeBackgroundView = NSView()
    private let badgeField = NSTextField(labelWithString: "")
    private let symbolView = NSImageView()
    private var trackingArea: NSTrackingArea?
    private var isHovered = false
    private var currentTheme: AppTheme?
    private var currentBadgeStyle: BadgeStyle = .off
    private var currentEnabled = true
    private let originalCaption: String

    init(title: String, symbolName: String, caption: String) {
        originalCaption = caption
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        isBordered = false
        bezelStyle = .regularSquare
        setButtonType(.momentaryChange)
        imagePosition = .imageOnly

        layer?.cornerRadius = QuickControlsLayout.featureTileCornerRadius

        gradientLayer.startPoint = CGPoint(x: 0, y: 1)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        gradientLayer.cornerRadius = QuickControlsLayout.featureTileCornerRadius

        borderLayer.borderWidth = 1
        borderLayer.cornerRadius = QuickControlsLayout.featureTileCornerRadius

        iconBadgeView.translatesAutoresizingMaskIntoConstraints = false
        iconBadgeView.wantsLayer = true
        iconBadgeView.layer?.cornerRadius = 11

        titleField.translatesAutoresizingMaskIntoConstraints = false
        titleField.stringValue = title
        titleField.lineBreakMode = .byWordWrapping
        titleField.maximumNumberOfLines = 2
        titleField.alignment = .center

        badgeBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        badgeBackgroundView.wantsLayer = true
        badgeBackgroundView.layer?.cornerRadius = 11
        badgeBackgroundView.layer?.masksToBounds = true

        badgeField.translatesAutoresizingMaskIntoConstraints = false
        badgeField.alignment = .center
        badgeField.lineBreakMode = .byClipping
        badgeField.maximumNumberOfLines = 1

        captionField.translatesAutoresizingMaskIntoConstraints = false
        captionField.stringValue = caption.uppercased()
        captionField.alignment = .center

        symbolView.translatesAutoresizingMaskIntoConstraints = false
        symbolView.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: title)
        symbolView.symbolConfiguration = .init(pointSize: 14, weight: .semibold)

        iconBadgeView.addSubview(symbolView)
        badgeBackgroundView.addSubview(badgeField)
        addSubview(iconBadgeView)
        addSubview(captionField)
        addSubview(titleField)
        addSubview(badgeBackgroundView)

        NSLayoutConstraint.activate([
            iconBadgeView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: QuickControlsLayout.headerIconInsetLeading),
            iconBadgeView.topAnchor.constraint(equalTo: topAnchor, constant: QuickControlsLayout.headerIconInsetTop),
            iconBadgeView.widthAnchor.constraint(equalToConstant: 30),
            iconBadgeView.heightAnchor.constraint(equalToConstant: 30),

            symbolView.centerXAnchor.constraint(equalTo: iconBadgeView.centerXAnchor),
            symbolView.centerYAnchor.constraint(equalTo: iconBadgeView.centerYAnchor),
            symbolView.widthAnchor.constraint(equalToConstant: 16),
            symbolView.heightAnchor.constraint(equalToConstant: 16),

            badgeBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -QuickControlsLayout.badgeInsetTrailing),
            badgeBackgroundView.topAnchor.constraint(equalTo: topAnchor, constant: QuickControlsLayout.badgeInsetTop),
            badgeBackgroundView.widthAnchor.constraint(greaterThanOrEqualToConstant: 46),
            badgeBackgroundView.heightAnchor.constraint(equalToConstant: 22),

            badgeField.centerXAnchor.constraint(equalTo: badgeBackgroundView.centerXAnchor),
            badgeField.centerYAnchor.constraint(equalTo: badgeBackgroundView.centerYAnchor),
            badgeField.leadingAnchor.constraint(greaterThanOrEqualTo: badgeBackgroundView.leadingAnchor, constant: 10),
            badgeField.trailingAnchor.constraint(lessThanOrEqualTo: badgeBackgroundView.trailingAnchor, constant: -10),

            captionField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: QuickControlsLayout.titleInsetHorizontal),
            captionField.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -QuickControlsLayout.titleInsetHorizontal),
            captionField.bottomAnchor.constraint(equalTo: titleField.topAnchor, constant: -4),

            titleField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: QuickControlsLayout.titleInsetHorizontal),
            titleField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -QuickControlsLayout.titleInsetHorizontal),
            titleField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -QuickControlsLayout.titleInsetBottom)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        gradientLayer.frame = bounds
        borderLayer.frame = bounds

        if gradientLayer.superlayer == nil {
            layer?.insertSublayer(gradientLayer, at: 0)
        }
        if borderLayer.superlayer == nil {
            layer?.addSublayer(borderLayer)
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let trackingArea {
            removeTrackingArea(trackingArea)
        }

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .mouseEnteredAndExited, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        self.trackingArea = trackingArea
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        isHovered = true
        applyInteractionState(animated: true)
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        isHovered = false
        applyInteractionState(animated: true)
    }

    override func mouseDown(with event: NSEvent) {
        animatePress(scale: 0.985)
        super.mouseDown(with: event)
        animatePress(scale: 1)
    }

    func update(
        badgeText: String,
        badgeStyle: BadgeStyle,
        enabled: Bool,
        theme: AppTheme,
        alternate: Bool,
        symbolName: String? = nil,
        captionOverride: String? = nil
    ) {
        let previousBadgeStyle = currentBadgeStyle
        badgeField.stringValue = badgeText
        isEnabled = enabled
        alphaValue = enabled ? 1 : 0.72
        gradientLayer.colors = (alternate ? theme.tileSecondaryGradient : theme.tileGradient).map(\.cgColor)
        borderLayer.borderColor = theme.panelBorder.withAlphaComponent(enabled ? 0.36 : 0.18).cgColor
        titleField.font = theme.quickControlsTileTitleFont
        captionField.font = theme.quickControlsTileCaptionFont
        badgeField.font = theme.quickControlsBadgeFont
        let foreground = theme.unifiedTileForegroundColor
        currentTheme = theme
        currentBadgeStyle = badgeStyle
        currentEnabled = enabled
        titleField.textColor = foreground
        captionField.textColor = foreground.withAlphaComponent(0.8)
        captionField.stringValue = (captionOverride ?? originalCaption).uppercased()

        if let symbolName, let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: titleField.stringValue) {
            symbolView.image = image
        }

        switch badgeStyle {
        case .on:
            iconBadgeView.layer?.backgroundColor = theme.quickControlEnabledFill.cgColor
            symbolView.contentTintColor = theme.quickControlEnabledTextColor
            badgeField.textColor = theme.quickControlEnabledTextColor
            badgeBackgroundView.layer?.backgroundColor = theme.quickControlEnabledFill.cgColor
        case .off:
            iconBadgeView.layer?.backgroundColor = theme.quickControlOffFill.cgColor
            symbolView.contentTintColor = theme.quickControlOffTextColor
            badgeField.textColor = theme.quickControlOffTextColor
            badgeBackgroundView.layer?.backgroundColor = theme.quickControlOffFill.withAlphaComponent(0.34).cgColor
        case .disabled:
            iconBadgeView.layer?.backgroundColor = theme.quickControlDisabledFill.cgColor
            symbolView.contentTintColor = theme.quickControlDisabledTextColor
            badgeField.textColor = theme.quickControlDisabledTextColor
            badgeBackgroundView.layer?.backgroundColor = theme.quickControlDisabledFill.cgColor
        case .comingSoon:
            iconBadgeView.layer?.backgroundColor = theme.quickControlDisabledFill.withAlphaComponent(0.86).cgColor
            symbolView.contentTintColor = theme.quickControlDisabledTextColor
            badgeField.textColor = theme.quickControlDisabledTextColor.withAlphaComponent(0.92)
            badgeBackgroundView.layer?.backgroundColor = theme.quickControlDisabledFill.withAlphaComponent(0.74).cgColor
        }

        applyInteractionState(animated: false)

        if previousBadgeStyle != badgeStyle {
            animateStatusPulse()
        }
    }

    private func applyInteractionState(animated: Bool) {
        guard let layer else { return }

        let applyChanges = {
            let active = self.isHovered && self.currentEnabled
            if self.currentBadgeStyle == .on, let theme = self.currentTheme {
                layer.shadowColor = theme.quickControlEnabledFill.cgColor
                layer.shadowRadius = active ? 18 : 11
                layer.shadowOpacity = active ? 0.45 : 0.30
            } else {
                layer.shadowColor = NSColor.black.cgColor
                layer.shadowRadius = active ? 14 : 8
                layer.shadowOpacity = active ? 0.18 : 0.08
            }
            layer.shadowOffset = CGSize(width: 0, height: active ? 8 : 4)
            layer.transform = CATransform3DMakeScale(active ? 1.012 : 1, active ? 1.012 : 1, 1)
            self.borderLayer.borderWidth = self.isHovered ? 1.4 : (self.currentBadgeStyle == .on ? 1.2 : 1)
            self.badgeField.alphaValue = self.isHovered ? 1 : 0.96
        }

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = QuickControlsLayout.panelShowDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                applyChanges()
            }
        } else {
            applyChanges()
        }
    }

    private func animatePress(scale: CGFloat) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = QuickControlsLayout.tilePressDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            layer?.transform = CATransform3DMakeScale(scale, scale, 1)
        }
    }

    private func animateStatusPulse() {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 0.96
        animation.toValue = 1.0
        animation.duration = QuickControlsLayout.tileUpdateDuration
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        badgeBackgroundView.layer?.add(animation, forKey: "statusPulse")
        iconBadgeView.layer?.add(animation, forKey: "iconPulse")
    }
}

final class GradientPanelBackgroundView: NSView {
    private let gradientLayer = CAGradientLayer()
    private let borderLayer = CALayer()
    private let glossLayer = CAGradientLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = QuickControlsLayout.backgroundCornerRadius
        layer?.masksToBounds = true
        gradientLayer.startPoint = CGPoint(x: 0, y: 1)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        gradientLayer.cornerRadius = QuickControlsLayout.backgroundCornerRadius
        glossLayer.startPoint = CGPoint(x: 0, y: 1)
        glossLayer.endPoint = CGPoint(x: 1, y: 0)
        glossLayer.cornerRadius = QuickControlsLayout.backgroundCornerRadius
        borderLayer.borderWidth = 1
        borderLayer.cornerRadius = QuickControlsLayout.backgroundCornerRadius
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        gradientLayer.frame = bounds
        glossLayer.frame = bounds
        borderLayer.frame = bounds

        if gradientLayer.superlayer == nil {
            layer?.insertSublayer(gradientLayer, at: 0)
        }
        if glossLayer.superlayer == nil {
            layer?.insertSublayer(glossLayer, above: gradientLayer)
        }
        if borderLayer.superlayer == nil {
            layer?.addSublayer(borderLayer)
        }
    }

    func apply(theme: AppTheme) {
        layer?.backgroundColor = theme.settingsContentSurfaceColor.withAlphaComponent(1).cgColor
        gradientLayer.colors = theme.settingsWindowGradientColors
            .map { $0.withAlphaComponent(1).cgColor }
        glossLayer.colors = [
            theme.settingsAccentSoftFill.withAlphaComponent(theme.preferredColorScheme == .dark ? 0.08 : 0.16).cgColor,
            NSColor.clear.cgColor
        ]
        borderLayer.borderColor = theme.settingsSidebarBorderColor.cgColor
    }
}

final class ThemeLogoBadgeView: NSView {
    private let iconView = NSImageView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        layer?.cornerRadius = 17
        layer?.masksToBounds = true

        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(theme: AppTheme) {
        layer?.backgroundColor = theme.settingsAccentSoftFill.cgColor
        iconView.image = NSImage(systemSymbolName: theme.symbolName, accessibilityDescription: theme.name)
        iconView.symbolConfiguration = .init(pointSize: 17, weight: .bold)
        iconView.contentTintColor = theme.settingsTint
    }
}

final class PanelPillView: NSView {
    private let label = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        layer?.cornerRadius = 11
        layer?.masksToBounds = true

        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(text: String, fill: NSColor, textColor: NSColor) {
        label.stringValue = text
        label.textColor = textColor
        layer?.backgroundColor = fill.cgColor
    }
}
