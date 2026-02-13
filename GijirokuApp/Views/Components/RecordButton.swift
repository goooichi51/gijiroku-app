import SwiftUI

struct RecordButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 64, height: 64)
                    .shadow(color: .red.opacity(0.3), radius: 8, y: 4)
                Image(systemName: "mic.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
    }
}
