import SwiftUI

struct RecordingPulseView: View {
    let audioLevel: Float
    let isPaused: Bool

    @State private var animationPhase: CGFloat = 0

    var body: some View {
        ZStack {
            // 外側の円（3重目）
            Circle()
                .fill(Color.accentColor.opacity(0.08))
                .scaleEffect(isPaused ? 1.0 : 1.0 + CGFloat(audioLevel) * 0.5 + animationPhase * 0.15)
                .animation(isPaused ? .default : .easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animationPhase)

            // 中間の円（2重目）
            Circle()
                .fill(Color.accentColor.opacity(0.15))
                .scaleEffect(isPaused ? 0.7 : 0.7 + CGFloat(audioLevel) * 0.4 + animationPhase * 0.1)
                .animation(isPaused ? .default : .easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animationPhase)

            // 内側の円（1重目）
            Circle()
                .fill(Color.accentColor.opacity(0.25))
                .scaleEffect(isPaused ? 0.4 : 0.4 + CGFloat(audioLevel) * 0.3)
                .animation(.easeOut(duration: 0.1), value: audioLevel)

            // 中央のマイクアイコン
            Image(systemName: isPaused ? "mic.slash.fill" : "mic.fill")
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
        }
        .frame(width: 120, height: 120)
        .onAppear {
            animationPhase = 1
        }
        .onChange(of: isPaused) {
            animationPhase = isPaused ? 0 : 1
        }
        .accessibilityHidden(true)
    }
}
