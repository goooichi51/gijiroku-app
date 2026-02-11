import SwiftUI

struct FullTextTabView: View {
    let segments: [TranscriptionSegment]

    var body: some View {
        ScrollView {
            if segments.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "text.quote")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("文字起こしデータがありません")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(segments) { segment in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(segment.formattedStartTime)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .monospacedDigit()

                            Text(segment.text)
                                .font(.body)
                        }
                    }
                }
                .padding()
            }
        }
    }
}
