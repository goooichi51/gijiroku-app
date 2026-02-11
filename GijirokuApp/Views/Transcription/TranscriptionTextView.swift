import SwiftUI

struct TranscriptionTextView: View {
    let segments: [TranscriptionSegment]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(segments) { segment in
                    HStack(alignment: .top, spacing: 12) {
                        Text(segment.formattedStartTime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 50, alignment: .trailing)
                            .monospacedDigit()

                        Text(segment.text)
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
