import SwiftUI

struct SummaryTabView: View {
    let meeting: Meeting
    @State private var showCopiedToast = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // メタ情報
                metadataSection

                Divider()

                if let summary = meeting.summary {
                    summaryContent(summary)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "wand.and.stars")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("AI要約はまだ生成されていません")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                }
            }
            .padding()
        }
        .overlay(alignment: .bottom) {
            if showCopiedToast {
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
        .toolbar {
            if meeting.summary != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        copySummary()
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .accessibilityLabel("要約をコピー")
                }
            }
        }
    }

    private func copySummary() {
        guard let summary = meeting.summary else { return }
        UIPasteboard.general.string = summary.rawText
        withAnimation { showCopiedToast = true }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                Text(meeting.formattedDate)
            }
            .font(.subheadline)

            if !meeting.location.isEmpty {
                HStack {
                    Image(systemName: "mappin")
                        .foregroundColor(.secondary)
                    Text(meeting.location)
                }
                .font(.subheadline)
            }

            if !meeting.participants.isEmpty {
                HStack(alignment: .top) {
                    Image(systemName: "person.2")
                        .foregroundColor(.secondary)
                    Text(meeting.participants.joined(separator: ", "))
                }
                .font(.subheadline)
            }

        }
    }

    @ViewBuilder
    private func summaryContent(_ summary: MeetingSummary) -> some View {
        if meeting.isCustomTemplate {
            customSummary(summary)
        } else {
            switch meeting.template {
            case .standard:
                standardSummary(summary)
            case .simple:
                simpleSummary(summary)
            case .sales:
                salesSummary(summary)
            case .brainstorm:
                brainstormSummary(summary)
            }
        }
    }

    private func customSummary(_ summary: MeetingSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionView(title: meeting.effectiveTemplateName) {
                Text(summary.rawText)
            }
        }
    }

    private func standardSummary(_ summary: MeetingSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let agenda = summary.agenda, !agenda.isEmpty {
                SectionView(title: "議題") {
                    ForEach(Array(agenda.enumerated()), id: \.offset) { i, item in
                        Text("\(i + 1). \(item)")
                    }
                }
            }
            if let discussion = summary.discussion {
                SectionView(title: "議論内容") {
                    Text(discussion)
                }
            }
            if let decisions = summary.decisions, !decisions.isEmpty {
                SectionView(title: "決定事項") {
                    ForEach(decisions, id: \.self) { item in
                        BulletItem(text: item)
                    }
                }
            }
            if let actions = summary.actionItems, !actions.isEmpty {
                SectionView(title: "アクションアイテム") {
                    ForEach(actions) { action in
                        ActionItemRow(item: action)
                    }
                }
            }
        }
    }

    private func simpleSummary(_ summary: MeetingSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let points = summary.keyPoints, !points.isEmpty {
                SectionView(title: "要点まとめ") {
                    ForEach(points, id: \.self) { item in
                        BulletItem(text: item)
                    }
                }
            }
            if let nextActions = summary.nextActions, !nextActions.isEmpty {
                SectionView(title: "次回アクション") {
                    ForEach(nextActions, id: \.self) { item in
                        BulletItem(text: item)
                    }
                }
            }
        }
    }

    private func salesSummary(_ summary: MeetingSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let customer = summary.customerName {
                SectionView(title: "顧客名") { Text(customer) }
            }
            if let hearing = summary.hearingNotes {
                SectionView(title: "ヒアリング内容") { Text(hearing) }
            }
            if let proposals = summary.proposals, !proposals.isEmpty {
                SectionView(title: "提案事項") {
                    ForEach(proposals, id: \.self) { item in
                        BulletItem(text: item)
                    }
                }
            }
            if let deadline = summary.followUpDeadline {
                SectionView(title: "フォローアップ期限") { Text(deadline) }
            }
            if let actions = summary.actionItems, !actions.isEmpty {
                SectionView(title: "次回アクション") {
                    ForEach(actions) { action in
                        ActionItemRow(item: action)
                    }
                }
            }
        }
    }

    private func brainstormSummary(_ summary: MeetingSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let theme = summary.theme {
                SectionView(title: "テーマ") { Text(theme) }
            }
            if let ideas = summary.ideas, !ideas.isEmpty {
                SectionView(title: "アイデア一覧") {
                    ForEach(ideas) { idea in
                        HStack(alignment: .top) {
                            Text("・")
                            VStack(alignment: .leading) {
                                Text(idea.idea)
                                if let priority = idea.priority {
                                    Text("優先度: \(priority)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            if let steps = summary.nextSteps, !steps.isEmpty {
                SectionView(title: "ネクストステップ") {
                    ForEach(steps, id: \.self) { item in
                        BulletItem(text: item)
                    }
                }
            }
        }
    }
}

// MARK: - Helper Views

struct SectionView<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("■ \(title)")
                .font(.headline)
            content()
        }
    }
}

struct BulletItem: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("・")
            Text(text)
        }
    }
}

struct ActionItemRow: View {
    let item: ActionItem

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: item.isCompleted ? "checkmark.square" : "square")
                .foregroundColor(item.isCompleted ? .green : .secondary)
            VStack(alignment: .leading) {
                Text("\(item.assignee): \(item.task)")
                if let deadline = item.deadline {
                    Text("（\(deadline)まで）")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
