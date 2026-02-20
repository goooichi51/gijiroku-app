import SwiftUI

struct TranscriptionTextView: View {
    let segments: [TranscriptionSegment]

    private var groupedSegments: [(timestamp: String, text: String)] {
        guard !segments.isEmpty else { return [] }
        let intervalSeconds: TimeInterval = 600 // 10分
        var groups: [(timestamp: String, text: String)] = []
        var currentGroupStart = segments[0].startTime
        var currentTexts: [String] = []

        for segment in segments {
            if segment.startTime - currentGroupStart >= intervalSeconds && !currentTexts.isEmpty {
                groups.append((
                    timestamp: TranscriptionSegment.formatTime(currentGroupStart),
                    text: currentTexts.joined(separator: "")
                ))
                currentGroupStart = segment.startTime
                currentTexts = []
            }
            currentTexts.append(segment.text)
        }
        if !currentTexts.isEmpty {
            groups.append((
                timestamp: TranscriptionSegment.formatTime(currentGroupStart),
                text: currentTexts.joined(separator: "")
            ))
        }
        return groups
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(Array(groupedSegments.enumerated()), id: \.offset) { _, group in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(group.timestamp)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .monospacedDigit()

                        Text(group.text)
                            .font(.body)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("文字起こし全文")
        .navigationBarTitleDisplayMode(.inline)
    }
}
