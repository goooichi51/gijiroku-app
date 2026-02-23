import SwiftUI
import PDFKit

struct PDFPreviewView: View {
    let meeting: Meeting
    @AppStorage("selectedPDFDesign") private var selectedDesignRaw = PDFDesign.business.rawValue
    @State private var pdfData: Data?
    @State private var pdfFileURL: URL?
    @State private var generationError: String?
    @State private var pdfVersion = 0

    private var selectedDesign: PDFDesign {
        PDFDesign(rawValue: selectedDesignRaw) ?? .business
    }

    var body: some View {
        VStack(spacing: 0) {
            // デザインピッカー
            designPicker

            // PDFプレビュー
            if let data = pdfData {
                PDFKitView(data: data)
                    .id(pdfVersion)
            } else if let error = generationError {
                errorView(error)
            } else {
                ProgressView("PDF生成中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("PDFプレビュー")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let url = pdfFileURL {
                    ShareLink(item: url, preview: SharePreview(meeting.title.isEmpty ? "議事録" : meeting.title)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("PDFを共有")
                }
            }
        }
        .task {
            generatePDF(design: selectedDesign)
        }
    }

    private var designPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(PDFDesign.allCases) { design in
                    designCard(design)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func designCard(_ design: PDFDesign) -> some View {
        let isSelected = design.rawValue == selectedDesignRaw
        return Button {
            selectedDesignRaw = design.rawValue
            generatePDF(design: design)
        } label: {
            VStack(spacing: 6) {
                // デザイン別ミニチュアプレビュー
                designMiniature(design)
                    .padding(6)
                    .background(Color.white)
                    .cornerRadius(4)
                    .shadow(color: .black.opacity(0.05), radius: 2)

                Text(design.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? Color(design.primaryColor) : .secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(design.primaryColor) : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func designMiniature(_ design: PDFDesign) -> some View {
        switch design {
        case .business:
            // 枠付き + 中央タイトル + テーブル
            VStack(spacing: 3) {
                Rectangle()
                    .fill(Color(design.primaryColor).opacity(0.3))
                    .frame(width: 40, height: 3)
                Rectangle()
                    .fill(Color(design.secondaryColor))
                    .frame(width: 60, height: 8)
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 60, height: 2)
                }
            }
            .padding(4)
            .overlay(
                Rectangle()
                    .stroke(Color(design.primaryColor), lineWidth: 1)
            )
            .frame(width: 72, height: 50)

        case .corporate:
            // 上部帯 + 左アクセント + テキスト行
            VStack(alignment: .leading, spacing: 3) {
                Rectangle()
                    .fill(Color(design.primaryColor))
                    .frame(width: 68, height: 3)
                HStack(spacing: 3) {
                    Rectangle()
                        .fill(Color(design.primaryColor))
                        .frame(width: 2, height: 8)
                    Rectangle()
                        .fill(Color(design.primaryColor).opacity(0.3))
                        .frame(width: 30, height: 3)
                }
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 55, height: 2)
                }
            }
            .frame(width: 72, height: 50)

        case .modern:
            // 細いトップライン + すっきりしたレイアウト
            VStack(alignment: .leading, spacing: 4) {
                Rectangle()
                    .fill(Color(design.primaryColor))
                    .frame(width: 68, height: 2)
                Rectangle()
                    .fill(Color(design.primaryColor).opacity(0.2))
                    .frame(width: 45, height: 3)
                Spacer().frame(height: 2)
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 58, height: 2)
                }
            }
            .frame(width: 72, height: 50)

        case .minimal:
            // テキストのみ
            VStack(alignment: .leading, spacing: 4) {
                Rectangle()
                    .fill(Color(design.primaryColor).opacity(0.5))
                    .frame(width: 35, height: 3)
                Spacer().frame(height: 1)
                ForEach(0..<4, id: \.self) { _ in
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 55, height: 2)
                }
            }
            .frame(width: 72, height: 50)
        }
    }

    private func errorView(_ error: String) -> some View {
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
                generatePDF(design: selectedDesign)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func generatePDF(design: PDFDesign) {
        let data = PDFGenerator().generatePDF(from: meeting, design: design)
        if data.isEmpty {
            generationError = "議事録データが不足しているか、PDF生成中にエラーが発生しました。"
        } else {
            pdfData = data
            pdfVersion += 1
            savePDFToFile(data)
        }
    }

    private func savePDFToFile(_ data: Data) {
        let fileName = "\(meeting.title.isEmpty ? "議事録" : meeting.title).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: tempURL)
            pdfFileURL = tempURL
        } catch {
            generationError = "PDFファイルの保存に失敗しました: \(error.localizedDescription)"
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
