import SwiftUI

struct TemplateSelectionView: View {
    @Binding var selected: MeetingTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("テンプレート選択")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MeetingTemplate.allCases) { template in
                        TemplateCard(
                            template: template,
                            isSelected: selected == template
                        ) {
                            selected = template
                        }
                    }
                }
            }
        }
    }
}

struct TemplateCard: View {
    let template: MeetingTemplate
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: template.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)

                Text(template.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)

                Text(template.description)
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
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
