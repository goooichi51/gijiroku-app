import SwiftUI

struct MeetingListItemView: View {
    let meeting: Meeting

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.blue)
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
                    Text(meeting.formattedDuration)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Text(meeting.template.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)

                Spacer()

                StatusBadge(status: meeting.status)
            }
        }
        .padding(.vertical, 4)
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
