import UIKit

class PDFGenerator {
    // A4サイズ（ポイント単位）
    private let pageWidth: CGFloat = 595.28
    private let pageHeight: CGFloat = 841.89
    private let margin: CGFloat = 50
    private let frameMargin: CGFloat = 22

    private var contentWidth: CGFloat { pageWidth - margin * 2 }

    private var design: PDFDesign = .business

    // MARK: - Fonts

    private var titleFont: UIFont {
        switch design {
        case .business: return UIFont.systemFont(ofSize: 20, weight: .bold)
        case .corporate: return UIFont.systemFont(ofSize: 18, weight: .semibold)
        case .modern: return UIFont.systemFont(ofSize: 20, weight: .medium)
        case .minimal: return UIFont.systemFont(ofSize: 16, weight: .bold)
        }
    }

    private var headingFont: UIFont {
        switch design {
        case .business: return UIFont.systemFont(ofSize: 12, weight: .bold)
        case .corporate: return UIFont.systemFont(ofSize: 12, weight: .semibold)
        case .modern: return UIFont.systemFont(ofSize: 12, weight: .medium)
        case .minimal: return UIFont.systemFont(ofSize: 11, weight: .bold)
        }
    }

    private var bodyFont: UIFont {
        switch design {
        case .business: return UIFont.systemFont(ofSize: 10.5, weight: .regular)
        case .corporate: return UIFont.systemFont(ofSize: 10.5, weight: .regular)
        case .modern: return UIFont.systemFont(ofSize: 11, weight: .regular)
        case .minimal: return UIFont.systemFont(ofSize: 10.5, weight: .light)
        }
    }

    private let captionFont = UIFont.systemFont(ofSize: 8.5, weight: .regular)
    private let metadataFont = UIFont.systemFont(ofSize: 10, weight: .regular)
    private let metadataLabelFont = UIFont.systemFont(ofSize: 10, weight: .medium)

    // MARK: - Generate

    func generatePDF(from meeting: Meeting, design: PDFDesign = .business) -> Data {
        self.design = design

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
            drawPageDecoration(in: context)
            var y = margin

            // ヘッダー
            y = drawHeader(meeting: meeting, y: y, in: context)

            // メタ情報
            y = drawMetadata(meeting, at: y, in: context)

            // セパレータ
            y = drawContentSeparator(at: y, in: context)

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

    // MARK: - Page Decoration

    private func drawPageDecoration(in context: UIGraphicsPDFRendererContext) {
        switch design {
        case .business:
            // A4外枠（四角い枠）
            let frameRect = CGRect(
                x: frameMargin,
                y: frameMargin,
                width: pageWidth - frameMargin * 2,
                height: pageHeight - frameMargin * 2
            )
            design.primaryColor.setStroke()
            let path = UIBezierPath(rect: frameRect)
            path.lineWidth = 1.0
            path.stroke()

        case .corporate:
            // 上部カラー帯
            let bandRect = CGRect(x: 0, y: 0, width: pageWidth, height: 6)
            design.primaryColor.setFill()
            UIBezierPath(rect: bandRect).fill()

        case .modern:
            // 上部アクセントライン
            let lineRect = CGRect(x: 0, y: 0, width: pageWidth, height: 3)
            design.primaryColor.setFill()
            UIBezierPath(rect: lineRect).fill()

        case .minimal:
            break
        }
    }

    // MARK: - Header

    private func drawHeader(meeting: Meeting, y: CGFloat, in context: UIGraphicsPDFRendererContext) -> CGFloat {
        switch design {
        case .business:
            return drawBusinessHeader(meeting: meeting, y: y, in: context)
        case .corporate:
            return drawCorporateHeader(meeting: meeting, y: y, in: context)
        case .modern:
            return drawModernHeader(meeting: meeting, y: y, in: context)
        case .minimal:
            return drawMinimalHeader(meeting: meeting, y: y, in: context)
        }
    }

    private func drawBusinessHeader(meeting: Meeting, y: CGFloat, in context: UIGraphicsPDFRendererContext) -> CGFloat {
        var currentY = y

        // 中央「会議議事録」
        let attrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: design.primaryColor
        ]
        let title = "会議議事録"
        let titleSize = title.size(withAttributes: attrs)
        title.draw(at: CGPoint(x: (pageWidth - titleSize.width) / 2, y: currentY), withAttributes: attrs)
        currentY += titleSize.height + 6

        // 二重線
        design.primaryColor.setStroke()
        let thickLine = UIBezierPath()
        thickLine.move(to: CGPoint(x: margin, y: currentY))
        thickLine.addLine(to: CGPoint(x: pageWidth - margin, y: currentY))
        thickLine.lineWidth = 1.5
        thickLine.stroke()

        let thinLine = UIBezierPath()
        thinLine.move(to: CGPoint(x: margin, y: currentY + 3))
        thinLine.addLine(to: CGPoint(x: pageWidth - margin, y: currentY + 3))
        thinLine.lineWidth = 0.5
        thinLine.stroke()
        currentY += 12

        // 会議タイトル（中央）
        let meetingTitle = meeting.title.isEmpty ? "無題の議事録" : meeting.title
        let mtAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .bold),
            .foregroundColor: design.primaryColor
        ]
        let mtSize = meetingTitle.size(withAttributes: mtAttrs)
        meetingTitle.draw(at: CGPoint(x: (pageWidth - mtSize.width) / 2, y: currentY), withAttributes: mtAttrs)
        currentY += mtSize.height + 15

        return currentY
    }

    private func drawCorporateHeader(meeting: Meeting, y: CGFloat, in context: UIGraphicsPDFRendererContext) -> CGFloat {
        var currentY = y

        // 左太線アクセント + タイトル
        let accentRect = CGRect(x: margin, y: currentY, width: 4, height: titleFont.lineHeight + 2)
        design.primaryColor.setFill()
        UIBezierPath(rect: accentRect).fill()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: design.primaryColor
        ]
        "議事録".draw(at: CGPoint(x: margin + 10, y: currentY), withAttributes: attrs)
        currentY += titleFont.lineHeight + 8

        // 会議タイトル
        let meetingTitle = meeting.title.isEmpty ? "無題の議事録" : meeting.title
        let mtAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: UIColor.darkGray
        ]
        meetingTitle.draw(at: CGPoint(x: margin, y: currentY), withAttributes: mtAttrs)
        currentY += 22

        return currentY
    }

    private func drawModernHeader(meeting: Meeting, y: CGFloat, in context: UIGraphicsPDFRendererContext) -> CGFloat {
        var currentY = y

        let attrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: design.primaryColor
        ]
        "会議議事録".draw(at: CGPoint(x: margin, y: currentY), withAttributes: attrs)
        currentY += titleFont.lineHeight + 6

        // 会議タイトル
        let meetingTitle = meeting.title.isEmpty ? "無題の議事録" : meeting.title
        let mtAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]
        meetingTitle.draw(at: CGPoint(x: margin, y: currentY), withAttributes: mtAttrs)
        currentY += 22

        return currentY
    }

    private func drawMinimalHeader(meeting: Meeting, y: CGFloat, in context: UIGraphicsPDFRendererContext) -> CGFloat {
        var currentY = y

        // 会議タイトルをそのまま表示
        let meetingTitle = meeting.title.isEmpty ? "無題の議事録" : meeting.title
        let attrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: design.primaryColor
        ]
        meetingTitle.draw(at: CGPoint(x: margin, y: currentY), withAttributes: attrs)
        currentY += titleFont.lineHeight + 12

        return currentY
    }

    // MARK: - Metadata

    private func drawMetadata(_ meeting: Meeting, at y: CGFloat, in context: UIGraphicsPDFRendererContext) -> CGFloat {
        switch design {
        case .business:
            return drawBusinessMetadata(meeting, at: y, in: context)
        case .corporate:
            return drawCorporateMetadata(meeting, at: y, in: context)
        case .modern:
            return drawModernMetadata(meeting, at: y, in: context)
        case .minimal:
            return drawMinimalMetadata(meeting, at: y, in: context)
        }
    }

    private func drawBusinessMetadata(_ meeting: Meeting, at y: CGFloat, in context: UIGraphicsPDFRendererContext) -> CGFloat {
        var currentY = y

        // テーブル形式のメタ情報（セル罫線付き）
        let formatter = DateFormatter.japaneseFull
        let rows: [(String, String)] = [
            ("日  時", formatter.string(from: meeting.date)),
            ("場  所", meeting.location.isEmpty ? "−" : meeting.location),
            ("参加者", meeting.participants.isEmpty ? "−" : meeting.participants.joined(separator: "、"))
        ]

        let labelWidth: CGFloat = 65
        let rowHeight: CGFloat = 22

        design.primaryColor.withAlphaComponent(0.5).setStroke()

        for (label, value) in rows {
            // ラベルセル背景
            let labelRect = CGRect(x: margin, y: currentY, width: labelWidth, height: rowHeight)
            design.secondaryColor.setFill()
            UIBezierPath(rect: labelRect).fill()

            // ラベルセル罫線
            let labelBorder = UIBezierPath(rect: labelRect)
            labelBorder.lineWidth = 0.5
            labelBorder.stroke()

            // 値セル罫線
            let valueRect = CGRect(x: margin + labelWidth, y: currentY, width: contentWidth - labelWidth, height: rowHeight)
            let valueBorder = UIBezierPath(rect: valueRect)
            valueBorder.lineWidth = 0.5
            valueBorder.stroke()

            // ラベルテキスト
            let labelAttrs: [NSAttributedString.Key: Any] = [
                .font: metadataLabelFont,
                .foregroundColor: design.primaryColor
            ]
            label.draw(at: CGPoint(x: margin + 6, y: currentY + 4), withAttributes: labelAttrs)

            // 値テキスト
            let valueAttrs: [NSAttributedString.Key: Any] = [
                .font: metadataFont,
                .foregroundColor: UIColor.darkGray
            ]
            value.draw(at: CGPoint(x: margin + labelWidth + 8, y: currentY + 4), withAttributes: valueAttrs)

            currentY += rowHeight
        }

        return currentY + 15
    }

    private func drawCorporateMetadata(_ meeting: Meeting, at y: CGFloat, in context: UIGraphicsPDFRendererContext) -> CGFloat {
        var currentY = y

        let formatter = DateFormatter.japaneseFull
        let items: [(String, String)] = [
            ("日時", formatter.string(from: meeting.date)),
            ("場所", meeting.location.isEmpty ? "−" : meeting.location),
            ("参加者", meeting.participants.isEmpty ? "−" : meeting.participants.joined(separator: "、"))
        ]

        for (label, value) in items {
            let labelAttrs: [NSAttributedString.Key: Any] = [
                .font: metadataLabelFont,
                .foregroundColor: design.primaryColor
            ]
            let valueAttrs: [NSAttributedString.Key: Any] = [
                .font: metadataFont,
                .foregroundColor: UIColor.darkGray
            ]

            // ラベル
            label.draw(at: CGPoint(x: margin, y: currentY), withAttributes: labelAttrs)
            let labelSize = label.size(withAttributes: labelAttrs)

            // コロン + 値
            let colonValue = "：\(value)"
            colonValue.draw(at: CGPoint(x: margin + labelSize.width, y: currentY), withAttributes: valueAttrs)

            currentY += 18
        }

        // メタデータ下の横線
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: currentY))
        path.addLine(to: CGPoint(x: pageWidth - margin, y: currentY))
        design.primaryColor.withAlphaComponent(0.2).setStroke()
        path.lineWidth = 0.5
        path.stroke()

        return currentY + 12
    }

    private func drawModernMetadata(_ meeting: Meeting, at y: CGFloat, in context: UIGraphicsPDFRendererContext) -> CGFloat {
        var currentY = y

        let formatter = DateFormatter.japaneseFull
        let parts = [
            formatter.string(from: meeting.date),
            meeting.location.isEmpty ? nil : meeting.location,
            meeting.participants.isEmpty ? nil : meeting.participants.joined(separator: "、")
        ].compactMap { $0 }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9.5, weight: .regular),
            .foregroundColor: UIColor.gray
        ]

        let text = parts.joined(separator: "  ｜  ")
        let textSize = text.size(withAttributes: attrs)

        if textSize.width > contentWidth {
            // 幅に収まらない場合は改行
            for part in parts {
                part.draw(at: CGPoint(x: margin, y: currentY), withAttributes: attrs)
                currentY += 14
            }
        } else {
            text.draw(at: CGPoint(x: margin, y: currentY), withAttributes: attrs)
            currentY += textSize.height + 8
        }

        return currentY + 8
    }

    private func drawMinimalMetadata(_ meeting: Meeting, at y: CGFloat, in context: UIGraphicsPDFRendererContext) -> CGFloat {
        var currentY = y

        let formatter = DateFormatter.japaneseFull
        let items: [(String, String)] = [
            ("日時", formatter.string(from: meeting.date)),
            ("場所", meeting.location.isEmpty ? "−" : meeting.location),
            ("参加者", meeting.participants.isEmpty ? "−" : meeting.participants.joined(separator: "、"))
        ]

        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .medium),
            .foregroundColor: UIColor.gray
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .light),
            .foregroundColor: UIColor.darkGray
        ]

        for (label, value) in items {
            label.draw(at: CGPoint(x: margin, y: currentY), withAttributes: labelAttrs)
            let labelSize = label.size(withAttributes: labelAttrs)
            let spacing: CGFloat = 8
            value.draw(at: CGPoint(x: margin + labelSize.width + spacing, y: currentY), withAttributes: valueAttrs)
            currentY += 14
        }

        return currentY + 6
    }

    // MARK: - Content Separator

    private func drawContentSeparator(at y: CGFloat, in context: UIGraphicsPDFRendererContext) -> CGFloat {
        switch design {
        case .business:
            let path = UIBezierPath()
            path.move(to: CGPoint(x: margin, y: y))
            path.addLine(to: CGPoint(x: pageWidth - margin, y: y))
            design.primaryColor.setStroke()
            path.lineWidth = 1.0
            path.stroke()
            return y + 15

        case .corporate:
            return y + 8

        case .modern:
            let path = UIBezierPath()
            path.move(to: CGPoint(x: margin, y: y))
            path.addLine(to: CGPoint(x: pageWidth - margin, y: y))
            design.primaryColor.withAlphaComponent(0.15).setStroke()
            path.lineWidth = 0.5
            path.stroke()
            return y + 12

        case .minimal:
            let path = UIBezierPath()
            path.move(to: CGPoint(x: margin, y: y))
            path.addLine(to: CGPoint(x: margin + 40, y: y))
            UIColor.lightGray.setStroke()
            path.lineWidth = 0.5
            path.stroke()
            return y + 12
        }
    }

    // MARK: - Section Drawing

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
            drawPageDecoration(in: context)
            currentY = margin
        }

        // デザイン別のセクション見出し
        currentY = drawSectionHeading(title, at: currentY, in: context)

        // セクション内容
        currentY = drawText(content, font: bodyFont, y: currentY, in: context, pageNumber: &pageNumber)
        currentY += 15

        return currentY
    }

    private func drawSectionHeading(_ title: String, at y: CGFloat, in context: UIGraphicsPDFRendererContext) -> CGFloat {
        switch design {
        case .business:
            // ■ + テキスト + 下線
            let fullTitle = "■ \(title)"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: headingFont,
                .foregroundColor: design.primaryColor
            ]
            fullTitle.draw(at: CGPoint(x: margin, y: y), withAttributes: attrs)
            let lineY = y + headingFont.lineHeight + 3
            let path = UIBezierPath()
            path.move(to: CGPoint(x: margin, y: lineY))
            path.addLine(to: CGPoint(x: pageWidth - margin, y: lineY))
            design.primaryColor.withAlphaComponent(0.4).setStroke()
            path.lineWidth = 0.5
            path.stroke()
            return lineY + 8

        case .corporate:
            // 左太線 + テキスト
            let accentRect = CGRect(x: margin, y: y + 1, width: 3, height: headingFont.lineHeight)
            design.primaryColor.setFill()
            UIBezierPath(rect: accentRect).fill()

            let attrs: [NSAttributedString.Key: Any] = [
                .font: headingFont,
                .foregroundColor: design.primaryColor
            ]
            title.draw(at: CGPoint(x: margin + 8, y: y), withAttributes: attrs)
            return y + headingFont.lineHeight + 10

        case .modern:
            // テキスト + 細い下線
            let attrs: [NSAttributedString.Key: Any] = [
                .font: headingFont,
                .foregroundColor: design.primaryColor
            ]
            title.draw(at: CGPoint(x: margin, y: y), withAttributes: attrs)
            let lineY = y + headingFont.lineHeight + 2
            let path = UIBezierPath()
            path.move(to: CGPoint(x: margin, y: lineY))
            path.addLine(to: CGPoint(x: pageWidth - margin, y: lineY))
            design.primaryColor.withAlphaComponent(0.15).setStroke()
            path.lineWidth = 0.5
            path.stroke()
            return lineY + 8

        case .minimal:
            // 太字テキストのみ
            let attrs: [NSAttributedString.Key: Any] = [
                .font: headingFont,
                .foregroundColor: design.primaryColor
            ]
            title.draw(at: CGPoint(x: margin, y: y), withAttributes: attrs)
            return y + headingFont.lineHeight + 6
        }
    }

    // MARK: - Drawing Helpers

    private func drawText(_ text: String, font: UIFont, y: CGFloat, maxWidth: CGFloat? = nil, in context: UIGraphicsPDFRendererContext, pageNumber: inout Int) -> CGFloat {
        let width = maxWidth ?? contentWidth

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.darkGray,
            .paragraphStyle: paragraphStyle
        ]
        let attributedString = NSAttributedString(string: text, attributes: attrs)
        let rect = CGRect(x: margin, y: y, width: width, height: .greatestFiniteMagnitude)
        let boundingRect = attributedString.boundingRect(with: rect.size, options: [.usesLineFragmentOrigin], context: nil)

        var currentY = y

        // ページをまたぐ場合
        if currentY + boundingRect.height > pageHeight - margin - 30 {
            drawFooter(pageNumber: pageNumber, in: context)
            pageNumber += 1
            context.beginPage()
            drawPageDecoration(in: context)
            currentY = margin
        }

        let drawRect = CGRect(x: margin, y: currentY, width: width, height: boundingRect.height)
        attributedString.draw(in: drawRect)

        return currentY + boundingRect.height
    }

    // MARK: - Footer

    private func drawFooter(pageNumber: Int, in context: UIGraphicsPDFRendererContext) {
        let footerY = pageHeight - margin - 10

        // 上線
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: footerY))
        path.addLine(to: CGPoint(x: pageWidth - margin, y: footerY))

        switch design {
        case .business:
            design.primaryColor.withAlphaComponent(0.3).setStroke()
            path.lineWidth = 0.5
        case .corporate:
            design.primaryColor.withAlphaComponent(0.2).setStroke()
            path.lineWidth = 0.5
        case .modern:
            design.primaryColor.withAlphaComponent(0.1).setStroke()
            path.lineWidth = 0.3
        case .minimal:
            UIColor.lightGray.setStroke()
            path.lineWidth = 0.3
        }
        path.stroke()

        // ページ番号（中央）
        let attrs: [NSAttributedString.Key: Any] = [
            .font: captionFont,
            .foregroundColor: UIColor.gray
        ]
        let pageStr = "- \(pageNumber) -"
        let pageSize = pageStr.size(withAttributes: attrs)
        pageStr.draw(at: CGPoint(x: (pageWidth - pageSize.width) / 2, y: footerY + 4), withAttributes: attrs)
    }
}
