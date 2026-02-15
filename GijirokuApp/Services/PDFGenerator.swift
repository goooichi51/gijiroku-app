import UIKit

class PDFGenerator {
    // A4サイズ（ポイント単位）
    private let pageWidth: CGFloat = 595.28
    private let pageHeight: CGFloat = 841.89
    private let margin: CGFloat = 50

    private var contentWidth: CGFloat { pageWidth - margin * 2 }

    // フォント
    private let titleFont = UIFont.systemFont(ofSize: 20, weight: .bold)
    private let headingFont = UIFont.systemFont(ofSize: 14, weight: .bold)
    private let bodyFont = UIFont.systemFont(ofSize: 11, weight: .regular)
    private let captionFont = UIFont.systemFont(ofSize: 9, weight: .regular)
    private let metadataFont = UIFont.systemFont(ofSize: 10, weight: .regular)

    func generatePDF(from meeting: Meeting) -> Data {
        let pdfMetaData: [String: Any] = [
            kCGPDFContextTitle as String: meeting.title,
            kCGPDFContextCreator as String: "議事録アプリ"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData

        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        var pageNumber = 1

        return renderer.pdfData { context in
            context.beginPage()
            var y = margin

            // タイトル
            y = drawCenteredText("会 議 議 事 録", font: titleFont, y: y, in: context)
            y += 20

            // 区切り線
            y = drawSeparator(at: y, in: context)
            y += 10

            // メタ情報
            y = drawMetadata(meeting, at: y, in: context)

            // 区切り線
            y = drawSeparator(at: y, in: context)
            y += 15

            // 要約内容
            if let summary = meeting.summary {
                y = drawSummaryContent(meeting: meeting, summary: summary, y: y, context: context, pageNumber: &pageNumber)
            } else if let text = meeting.transcriptionText {
                y = drawSection(title: "文字起こし", content: text, y: y, context: context, pageNumber: &pageNumber)
            }

            // フッター
            drawFooter(pageNumber: pageNumber, in: context)
        }
    }

    // MARK: - Drawing Helpers

    private func drawCenteredText(_ text: String, font: UIFont, y: CGFloat, in context: UIGraphicsPDFRendererContext) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let size = text.size(withAttributes: attrs)
        let x = (pageWidth - size.width) / 2
        text.draw(at: CGPoint(x: x, y: y), withAttributes: attrs)
        return y + size.height
    }

    private func drawText(_ text: String, font: UIFont, y: CGFloat, maxWidth: CGFloat? = nil, in context: UIGraphicsPDFRendererContext, pageNumber: inout Int) -> CGFloat {
        let width = maxWidth ?? contentWidth
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let attributedString = NSAttributedString(string: text, attributes: attrs)
        let rect = CGRect(x: margin, y: y, width: width, height: .greatestFiniteMagnitude)
        let boundingRect = attributedString.boundingRect(with: rect.size, options: [.usesLineFragmentOrigin], context: nil)

        var currentY = y

        // ページをまたぐ場合
        if currentY + boundingRect.height > pageHeight - margin - 30 {
            drawFooter(pageNumber: pageNumber, in: context)
            pageNumber += 1
            context.beginPage()
            currentY = margin
        }

        let drawRect = CGRect(x: margin, y: currentY, width: width, height: boundingRect.height)
        attributedString.draw(in: drawRect)

        return currentY + boundingRect.height
    }

    private func drawSeparator(at y: CGFloat, in context: UIGraphicsPDFRendererContext) -> CGFloat {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: pageWidth - margin, y: y))
        UIColor.gray.setStroke()
        path.lineWidth = 0.5
        path.stroke()
        return y + 5
    }

    private func drawMetadata(_ meeting: Meeting, at y: CGFloat, in context: UIGraphicsPDFRendererContext) -> CGFloat {
        var currentY = y
        let attrs: [NSAttributedString.Key: Any] = [.font: metadataFont]
        let lineHeight: CGFloat = 18

        let formatter = DateFormatter.japaneseFull
        let items: [(String, String)] = [
            ("日時", formatter.string(from: meeting.date)),
            ("場所", meeting.location.isEmpty ? "-" : meeting.location),
            ("参加者", meeting.participants.isEmpty ? "-" : meeting.participants.joined(separator: ", ")),
        ]

        for (label, value) in items {
            let text = "\(label):    \(value)"
            text.draw(at: CGPoint(x: margin, y: currentY), withAttributes: attrs)
            currentY += lineHeight
        }

        return currentY + 5
    }

    private func drawSummaryContent(meeting: Meeting, summary: MeetingSummary, y: CGFloat, context: UIGraphicsPDFRendererContext, pageNumber: inout Int) -> CGFloat {
        var currentY = y

        if meeting.isCustomTemplate {
            let sectionTitle = meeting.effectiveTemplateName
            currentY = drawSection(title: sectionTitle, content: summary.rawText, y: currentY, context: context, pageNumber: &pageNumber)
            return currentY
        }

        switch meeting.template {
        case .standard:
            if let agenda = summary.agenda, !agenda.isEmpty {
                currentY = drawSection(title: "議題", content: agenda.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"), y: currentY, context: context, pageNumber: &pageNumber)
            }
            if let discussion = summary.discussion {
                currentY = drawSection(title: "議論内容", content: discussion, y: currentY, context: context, pageNumber: &pageNumber)
            }
            if let decisions = summary.decisions, !decisions.isEmpty {
                currentY = drawSection(title: "決定事項", content: decisions.map { "・\($0)" }.joined(separator: "\n"), y: currentY, context: context, pageNumber: &pageNumber)
            }
            if let actions = summary.actionItems, !actions.isEmpty {
                let text = actions.map { "・\($0.assignee): \($0.task)" + ($0.deadline.map { "（\($0)まで）" } ?? "") }.joined(separator: "\n")
                currentY = drawSection(title: "アクションアイテム", content: text, y: currentY, context: context, pageNumber: &pageNumber)
            }

        case .simple:
            if let points = summary.keyPoints, !points.isEmpty {
                currentY = drawSection(title: "要点まとめ", content: points.map { "・\($0)" }.joined(separator: "\n"), y: currentY, context: context, pageNumber: &pageNumber)
            }
            if let nextActions = summary.nextActions, !nextActions.isEmpty {
                currentY = drawSection(title: "次回アクション", content: nextActions.map { "・\($0)" }.joined(separator: "\n"), y: currentY, context: context, pageNumber: &pageNumber)
            }

        case .sales:
            if let customer = summary.customerName {
                currentY = drawSection(title: "顧客名", content: customer, y: currentY, context: context, pageNumber: &pageNumber)
            }
            if let hearing = summary.hearingNotes {
                currentY = drawSection(title: "ヒアリング内容", content: hearing, y: currentY, context: context, pageNumber: &pageNumber)
            }
            if let proposals = summary.proposals, !proposals.isEmpty {
                currentY = drawSection(title: "提案事項", content: proposals.map { "・\($0)" }.joined(separator: "\n"), y: currentY, context: context, pageNumber: &pageNumber)
            }

        case .brainstorm:
            if let theme = summary.theme {
                currentY = drawSection(title: "テーマ", content: theme, y: currentY, context: context, pageNumber: &pageNumber)
            }
            if let ideas = summary.ideas, !ideas.isEmpty {
                let text = ideas.map { "・\($0.idea)" + ($0.priority.map { "（優先度: \($0)）" } ?? "") }.joined(separator: "\n")
                currentY = drawSection(title: "アイデア一覧", content: text, y: currentY, context: context, pageNumber: &pageNumber)
            }
            if let steps = summary.nextSteps, !steps.isEmpty {
                currentY = drawSection(title: "ネクストステップ", content: steps.map { "・\($0)" }.joined(separator: "\n"), y: currentY, context: context, pageNumber: &pageNumber)
            }
        }

        return currentY
    }

    private func drawSection(title: String, content: String, y: CGFloat, context: UIGraphicsPDFRendererContext, pageNumber: inout Int) -> CGFloat {
        var currentY = y

        // ページ残りが少ない場合は改ページ
        if currentY > pageHeight - margin - 80 {
            drawFooter(pageNumber: pageNumber, in: context)
            pageNumber += 1
            context.beginPage()
            currentY = margin
        }

        // セクションタイトル
        let headingAttrs: [NSAttributedString.Key: Any] = [.font: headingFont]
        "■ \(title)".draw(at: CGPoint(x: margin, y: currentY), withAttributes: headingAttrs)
        currentY += headingFont.lineHeight + 8

        // セクション内容
        currentY = drawText(content, font: bodyFont, y: currentY, in: context, pageNumber: &pageNumber)
        currentY += 15

        return currentY
    }

    private func drawFooter(pageNumber: Int, in context: UIGraphicsPDFRendererContext) {
        _ = drawSeparator(at: pageHeight - margin - 15, in: context)
        let attrs: [NSAttributedString.Key: Any] = [.font: captionFont, .foregroundColor: UIColor.gray]
        let footer = "議事録アプリ で自動生成  \(pageNumber)"
        let size = footer.size(withAttributes: attrs)
        footer.draw(at: CGPoint(x: (pageWidth - size.width) / 2, y: pageHeight - margin), withAttributes: attrs)
    }
}
