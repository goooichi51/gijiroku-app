import SwiftUI

struct ParticipantTagView: View {
    @Binding var participants: [String]
    @State private var newParticipant = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 参加者タグ
            FlowLayout(spacing: 8) {
                ForEach(participants, id: \.self) { name in
                    HStack(spacing: 4) {
                        Text(name)
                            .font(.subheadline)
                        Button {
                            participants.removeAll { $0 == name }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .cornerRadius(16)
                }
            }

            // 追加入力
            HStack {
                TextField("参加者を追加", text: $newParticipant)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { addParticipant() }

                Button {
                    addParticipant()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
                .disabled(newParticipant.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func addParticipant() {
        let name = newParticipant.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !participants.contains(name) else { return }
        participants.append(name)
        newParticipant = ""
    }
}

// シンプルなFlowLayout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(subviews: subviews, proposal: proposal)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(subviews: subviews, proposal: proposal)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(subviews: Subviews, proposal: ProposedViewSize) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}
