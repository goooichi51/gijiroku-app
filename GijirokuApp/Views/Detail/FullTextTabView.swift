import SwiftUI

struct FullTextTabView: View {
    let segments: [TranscriptionSegment]
    @State private var showCopiedToast = false

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
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(Array(groupedSegments.enumerated()), id: \.offset) { _, group in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(group.timestamp)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                                .monospacedDigit()

                            Text(group.text)
                                .font(.body)
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding()
            }
        }
        .overlay(alignment: .bottom) {
            if showCopiedToast {
                copiedToast
            }
        }
        .toolbar {
            if !segments.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        copyAllText()
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .accessibilityLabel("全文をコピー")
                }
            }
        }
    }

    private func copyAllText() {
        let fullText = groupedSegments.map { "[\($0.timestamp)]\n\($0.text)" }.joined(separator: "\n\n")
        UIPasteboard.general.string = fullText
        showCopiedToast = true
    }

    private var copiedToast: some View {
        Text("コピーしました")
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .padding(.bottom, 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { showCopiedToast = false }
                }
            }
    }
}
