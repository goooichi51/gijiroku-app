import SwiftUI

struct WatchWaveformView: View {
    let level: Float
    let isActive: Bool

    @State private var bars: [CGFloat] = Array(repeating: 0.1, count: 7)

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<7, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(isActive ? Color.green : Color.gray)
                    .frame(width: 4, height: max(4, bars[index] * 30))
            }
        }
        .onChange(of: level) { _, newLevel in
            guard isActive else {
                withAnimation(.easeOut(duration: 0.3)) {
                    bars = Array(repeating: 0.1, count: 7)
                }
                return
            }
            withAnimation(.easeInOut(duration: 0.15)) {
                for i in 0..<7 {
                    let variation = CGFloat.random(in: -0.2...0.2)
                    bars[i] = max(0.1, min(1.0, CGFloat(newLevel) + variation))
                }
            }
        }
    }
}
