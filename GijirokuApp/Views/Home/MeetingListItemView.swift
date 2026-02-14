import SwiftUI

struct MeetingListItemView: View {
    let meeting: Meeting

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: meeting.template.icon)
                    .foregroundColor(templateColor)
                    .accessibilityHidden(true)
                Text(meeting.title.isEmpty ? "無題の議事録" : meeting.title)
                    .font(.headline)
                    .lineLimit(1)
            }

            HStack {
                Text(meeting.formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let duration = meeting.audioDuration, duration > 0 {
                    Text("・")
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                    Text(meeting.formattedDuration)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if !meeting.participants.isEmpty {
                    Text("・")
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                    Image(systemName: "person.2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                    Text("\(meeting.participants.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Text(meeting.template.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(templateColor.opacity(0.1))
                    .foregroundColor(templateColor)
                    .cornerRadius(4)

                Spacer()

                StatusBadge(status: meeting.status)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var parts = [meeting.title.isEmpty ? "無題の議事録" : meeting.title]
        parts.append(meeting.formattedDate)
        if let duration = meeting.audioDuration, duration > 0 {
            parts.append(meeting.formattedDuration)
        }
        if !meeting.participants.isEmpty {
            parts.append("参加者\(meeting.participants.count)人")
        }
        parts.append(meeting.template.displayName)
        parts.append(meeting.status.displayName)
        return parts.joined(separator: "、")
    }

    private var templateColor: Color {
        switch meeting.template {
        case .standard: return .blue
        case .simple: return .gray
        case .sales: return .orange
        case .brainstorm: return .purple
        }
    }
}

struct StatusBadge: View {
    let status: MeetingStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(status.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("ステータス: \(status.displayName)")
    }

    private var statusColor: Color {
        switch status {
        case .recording: return .red
        case .transcribing, .summarizing: return .orange
        case .readyForSummary: return .yellow
        case .completed: return .green
        }
    }
}
