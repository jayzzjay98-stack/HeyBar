import AppKit
import SwiftUI

final class CleanKeyOverlayState: ObservableObject {
    @Published var escTapProgress: Double = 0
    @Published var remainingSeconds: Int = 0
}

struct CleanKeyOverlayView: View {
    @ObservedObject var state: CleanKeyOverlayState
    let onStop: () -> Void
    @State private var pulse = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(nsColor: ThemeCatalog.hex(0x10131C)),
                    Color(nsColor: ThemeCatalog.hex(0x15263B)),
                    Color(nsColor: ThemeCatalog.hex(0x0A111B))
                ],
                startPoint: pulse ? .topLeading : .bottomLeading,
                endPoint: pulse ? .bottomTrailing : .topTrailing
            )
            .ignoresSafeArea()

            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.82))
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 164, height: 164)
                        .blur(radius: 18)

                    Circle()
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                        .frame(width: 148, height: 148)

                    Image(systemName: "sparkles")
                        .font(.system(size: 58, weight: .bold))
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
                }

                VStack(spacing: 10) {
                    Text("CleanKey Active")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Keyboard and mouse are locked so you can clean safely.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                }

                Text(timeText)
                    .font(.system(size: 78, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()

                VStack(spacing: 10) {
                    Text("Press ESC 5 times to unlock")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.86))

                    CleanKeyEscProgressBar(progress: state.escTapProgress)
                }

                Button {
                    onStop()
                } label: {
                    Label("Stop CleanKey", systemImage: "lock.open.fill")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(nsColor: ThemeCatalog.hex(0x6A8DFF)))
            }
            .padding(32)
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: true)) {
                pulse.toggle()
            }
        }
    }

    private var timeText: String {
        let mins = state.remainingSeconds / 60
        let secs = state.remainingSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

private struct CleanKeyEscProgressBar: View {
    let progress: Double

    private var stepCount: Int {
        Int(round(progress * 5))
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.12))
                    .frame(width: 240, height: 10)
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    )

                if progress > 0 {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(nsColor: ThemeCatalog.hex(0x7CB0FF)), Color(nsColor: ThemeCatalog.hex(0x78E1C0))],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 240 * CGFloat(stepCount) / 5.0, height: 10)
                        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: stepCount)
                }
            }

            if progress > 0 {
                Text("\(stepCount * 20)%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}
