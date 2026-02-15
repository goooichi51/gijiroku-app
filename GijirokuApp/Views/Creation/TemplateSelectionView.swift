import SwiftUI

struct TemplateSelectionView: View {
    @Binding var selected: MeetingTemplate
    var selectedCustomTemplateId: Binding<UUID?>?
    @ObservedObject private var planManager = PlanManager.shared
    @ObservedObject private var customStore = CustomTemplateStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("テンプレート選択")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // 組み込みテンプレート
                    ForEach(MeetingTemplate.allCases) { template in
                        let isAvailable = planManager.isTemplateAvailable(template)
                        let isSelected = selected == template && selectedCustomTemplateId?.wrappedValue == nil
                        TemplateCard(
                            template: template,
                            isSelected: isSelected,
                            isLocked: !isAvailable
                        ) {
                            if isAvailable {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selected = template
                                    selectedCustomTemplateId?.wrappedValue = nil
                                }
                            }
                        }
                        .accessibilityLabel("\(template.displayName)テンプレート")
                        .accessibilityHint(isAvailable ? "タップして選択" : "Standardプランで利用可能")
                    }

                    // カスタムテンプレート
                    ForEach(customStore.templates) { custom in
                        let isSelected = selectedCustomTemplateId?.wrappedValue == custom.id
                        CustomTemplateCard(
                            customTemplate: custom,
                            isSelected: isSelected
                        ) {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedCustomTemplateId?.wrappedValue = custom.id
                            }
                        }
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

struct CustomTemplateCard: View {
    let customTemplate: CustomTemplate
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: customTemplate.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .teal)

                Text(customTemplate.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)

                Text(customTemplate.templateDescription)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .frame(width: 120, height: 140)
            .padding(12)
            .background(isSelected ? Color.teal : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.teal : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
