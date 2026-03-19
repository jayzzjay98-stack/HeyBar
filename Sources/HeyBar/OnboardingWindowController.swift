import AppKit
import ApplicationServices
import SwiftUI

// MARK: - Window Controller

private enum OnboardingLayout {
    static let windowSize = NSSize(width: 560, height: 440)
    static let stepTransitionDuration: TimeInterval = 0.22
    static let buttonPressDuration: TimeInterval = 0.1
}

@MainActor
final class OnboardingWindowController: NSWindowController {
    private var hostingController: NSHostingController<OnboardingView>?
    private let onComplete: () -> Void

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: OnboardingLayout.windowSize),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)

        let view = OnboardingView(onComplete: onComplete)
        let hc = NSHostingController(rootView: view)
        hostingController = hc
        window.contentViewController = hc
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func present() {
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Onboarding View

private struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var step = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(nsColor: ThemeCatalog.hex(0x0D1117)),
                    Color(nsColor: ThemeCatalog.hex(0x131C2E))
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                stepIndicator
                    .padding(.top, 36)
                    .padding(.bottom, 8)

                Group {
                    switch step {
                    case 0: welcomeStep
                    case 1: permissionsStep
                    default: doneStep
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(reduceMotion ? .opacity : .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(reduceMotion ? .none : .easeOut(duration: OnboardingLayout.stepTransitionDuration), value: step)

                navigationBar
                    .padding(.horizontal, 40)
                    .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(.dark)
        .frame(width: OnboardingLayout.windowSize.width, height: OnboardingLayout.windowSize.height)
    }

    // MARK: Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { i in
                Capsule()
                    .fill(i == step ? Color.white : Color.white.opacity(0.18))
                    .frame(width: i == step ? 22 : 6, height: 6)
                    .animation(reduceMotion ? .none : .easeOut(duration: OnboardingLayout.stepTransitionDuration), value: step)
            }
        }
    }

    // MARK: Welcome Step

    private var welcomeStep: some View {
        VStack(spacing: 14) {
            Spacer()

            Image(systemName: "menubar.rectangle")
                .font(.system(size: 54, weight: .ultraLight))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(nsColor: ThemeCatalog.hex(0x8FE3D1)),
                            Color(nsColor: ThemeCatalog.hex(0x7CB0FF))
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.bottom, 6)

            Text("HeyBar lives in your menu bar")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("Click the HeyBar icon to open Quick Controls.\nRight-click (or long-press) to open Settings.")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(5)

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: Permissions Step

    private var permissionsStep: some View {
        VStack(spacing: 18) {
            Spacer()

            Text("Allow a few permissions")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            VStack(spacing: 10) {
                permissionRow(
                    icon: "hand.raised.fill",
                    title: "Accessibility",
                    description: "Required by CleanKey to lock keyboard and mouse while you clean.",
                    action: {
                        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
                        _ = AXIsProcessTrustedWithOptions(options)
                    }
                )
                permissionRow(
                    icon: "gearshape.2.fill",
                    title: "Automation",
                    description: "Required by Hide Dock and Hide Bar to control System Events.",
                    action: { SystemSettingsNavigator.openAutomationPrivacy() }
                )
            }
            .padding(.horizontal, 40)

            Text("You can grant these later from Settings if you skip now.")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.35))

            Spacer()
        }
    }

    private func permissionRow(
        icon: String,
        title: String,
        description: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color(nsColor: ThemeCatalog.hex(0x8FE3D1)))
                .frame(width: 38, height: 38)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button("Allow") { action() }
                .buttonStyle(OnboardingPillButtonStyle())
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.09), lineWidth: 1)
        )
    }

    // MARK: Done Step

    private var doneStep: some View {
        VStack(spacing: 14) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 54, weight: .ultraLight))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(nsColor: ThemeCatalog.hex(0x8FE3D1)),
                            Color(nsColor: ThemeCatalog.hex(0x7CB0FF))
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.bottom, 6)

            Text("You're all set")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("HeyBar is ready. Click the icon in your menu bar\nany time to open Quick Controls.")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(5)

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: Navigation Bar

    private var navigationBar: some View {
        HStack {
            if step > 0 {
                Button("Back") {
                    withAnimation(reduceMotion ? nil : .default) { step -= 1 }
                }
                .buttonStyle(OnboardingSecondaryButtonStyle())
            }

            Spacer()

            if step < 2 {
                Button(step == 1 ? "Continue" : "Get Started") {
                    withAnimation(reduceMotion ? nil : .default) { step += 1 }
                }
                .buttonStyle(OnboardingPrimaryButtonStyle())
            } else {
                Button("Open HeyBar") {
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    onComplete()
                }
                .buttonStyle(OnboardingPrimaryButtonStyle())
            }
        }
    }
}

// MARK: - Button Styles

private struct OnboardingPrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(Color(nsColor: ThemeCatalog.hex(0x0D1117)))
            .padding(.horizontal, 24)
            .padding(.vertical, 11)
            .background(
                LinearGradient(
                    colors: [
                        Color(nsColor: ThemeCatalog.hex(0x8FE3D1)),
                        Color(nsColor: ThemeCatalog.hex(0x7CB0FF))
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.97 : 1))
            .animation(reduceMotion ? .none : .easeOut(duration: OnboardingLayout.buttonPressDuration), value: configuration.isPressed)
    }
}

private struct OnboardingSecondaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.5))
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.97 : 1))
            .animation(reduceMotion ? .none : .easeOut(duration: OnboardingLayout.buttonPressDuration), value: configuration.isPressed)
    }
}

private struct OnboardingPillButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.12))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.96 : 1))
            .animation(reduceMotion ? .none : .easeOut(duration: OnboardingLayout.buttonPressDuration), value: configuration.isPressed)
    }
}
