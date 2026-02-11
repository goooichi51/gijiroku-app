import SwiftUI
import PDFKit

struct PDFPreviewView: View {
    let meeting: Meeting
    @State private var pdfData: Data?
    @State private var showShareSheet = false

    var body: some View {
        VStack {
            if let data = pdfData {
                PDFKitView(data: data)
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
            pdfData = PDFGenerator().generatePDF(from: meeting)
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

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(data: data)
    }
}
