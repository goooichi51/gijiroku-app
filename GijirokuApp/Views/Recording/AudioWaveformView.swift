import SwiftUI

struct AudioWaveformView: View {
    let level: Float
    @State private var levels: [Float] = Array(repeating: 0, count: 50)

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: 2) {
                ForEach(0..<levels.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor(for: index))
                        .frame(
                            width: max(2, (geometry.size.width - CGFloat(levels.count - 1) * 2) / CGFloat(levels.count)),
                            height: max(4, CGFloat(levels[index]) * geometry.size.height * 0.8)
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: level) { _, newLevel in
            levels.removeFirst()
            levels.append(newLevel)
        }
    }

    private func barColor(for index: Int) -> Color {
        let position = Float(index) / Float(levels.count)
        if position > 0.8 {
            return .blue
        }
        return .blue.opacity(Double(0.3 + position * 0.7))
    }
}
