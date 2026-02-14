import SwiftUI

struct FullTextTabView: View {
    let segments: [TranscriptionSegment]
    @State private var showCopiedToast = false

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
                                .textSelection(.enabled)
                        }
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = segment.text
                                showCopiedToast = true
                            } label: {
                                Label("コピー", systemImage: "doc.on.doc")
                            }
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
        let fullText = segments.map { "[\($0.formattedStartTime)] \($0.text)" }.joined(separator: "\n")
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
