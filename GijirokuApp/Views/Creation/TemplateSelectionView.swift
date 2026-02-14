import SwiftUI

struct TemplateSelectionView: View {
    @Binding var selected: MeetingTemplate
    @ObservedObject private var planManager = PlanManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("テンプレート選択")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MeetingTemplate.allCases) { template in
                        let isAvailable = planManager.isTemplateAvailable(template)
                        TemplateCard(
                            template: template,
                            isSelected: selected == template,
                            isLocked: !isAvailable
                        ) {
                            if isAvailable {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selected = template
                                }
                            }
                        }
                        .accessibilityLabel("\(template.displayName)テンプレート")
                        .accessibilityHint(isAvailable ? "タップして選択" : "Standardプランで利用可能")
                    }
                }
            }

            if planManager.currentPlan == .free {
                Text("Standardプランで全テンプレートが利用可能")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct TemplateCard: View {
    let template: MeetingTemplate
    let isSelected: Bool
    var isLocked: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: template.icon)
                        .font(.title2)
                        .foregroundColor(isLocked ? .secondary : (isSelected ? .white : .blue))

                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .offset(x: 8, y: -4)
                    }
                }

                Text(template.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isLocked ? .secondary : (isSelected ? .white : .primary))

                Text(template.description)
                    .font(.caption2)
                    .foregroundColor(isLocked ? .secondary.opacity(0.7) : (isSelected ? .white.opacity(0.8) : .secondary))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if isSelected && !isLocked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .frame(width: 120, height: 140)
            .padding(12)
            .background(isLocked ? Color(.systemGray5) : (isSelected ? Color.blue : Color(.systemGray6)))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected && !isLocked ? Color.blue : Color.clear, lineWidth: 2)
            )
            .opacity(isLocked ? 0.7 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
    }
}
