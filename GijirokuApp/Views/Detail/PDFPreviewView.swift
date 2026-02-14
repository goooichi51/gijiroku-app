import SwiftUI
import PDFKit

struct PDFPreviewView: View {
    let meeting: Meeting
    @State private var pdfData: Data?
    @State private var showShareSheet = false
    @State private var generationError: String?

    var body: some View {
        VStack {
            if let data = pdfData {
                PDFKitView(data: data)
            } else if let error = generationError {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("PDF生成に失敗しました")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("再試行") {
                        generationError = nil
                        generatePDF()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                ProgressView("PDF生成中...")
            }
        }
        .navigationTitle("PDFプレビュー")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(pdfData == nil)
                .accessibilityLabel("PDFを共有")
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let data = pdfData {
                let fileName = "\(meeting.title.isEmpty ? "議事録" : meeting.title).pdf"
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                let _ = try? data.write(to: tempURL)
                ShareSheet(activityItems: [tempURL])
            }
        }
        .task {
            generatePDF()
        }
    }

    private func generatePDF() {
        let data = PDFGenerator().generatePDF(from: meeting)
        if data.isEmpty {
            generationError = "議事録データが不足しているか、PDF生成中にエラーが発生しました。"
        } else {
            pdfData = data
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.document = PDFDocument(data: data)
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}
