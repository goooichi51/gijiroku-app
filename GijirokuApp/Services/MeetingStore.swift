import Foundation

@MainActor
class MeetingStore: ObservableObject {
    @Published var meetings: [Meeting] = []

    let syncService = SyncService()
    private let storageKey = "meetings_data"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        load()
    }

    func load() {
        guard let data = userDefaults.data(forKey: storageKey) else { return }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            meetings = try decoder.decode([Meeting].self, from: data)
            // 保存済み議事録のステータスを補正（録音中のまま保存された場合の修正）
            for i in meetings.indices {
                let corrected = meetings[i].correctedStatus
                if corrected != meetings[i].status {
                    meetings[i].status = corrected
                }
            }
            meetings.sort { $0.date > $1.date }
        } catch {
            AppLogger.store.error("議事録データの読み込みに失敗しました: \(error.localizedDescription)")
        }
    }

    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(meetings)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            AppLogger.store.error("議事録データの保存に失敗しました: \(error.localizedDescription)")
        }
    }

    func add(_ meeting: Meeting) {
        meetings.insert(meeting, at: 0)
        save()
        Task { await syncService.uploadMeeting(meeting) }
    }

    func update(_ meeting: Meeting) {
        if let index = meetings.firstIndex(where: { $0.id == meeting.id }) {
            var updated = meeting
            updated.updatedAt = Date()
            meetings[index] = updated
            save()
            Task { await syncService.uploadMeeting(updated) }
        }
    }

    func delete(_ meeting: Meeting) {
        let id = meeting.id
        meetings.removeAll { $0.id == id }
        save()
        Task { await syncService.deleteMeeting(id: id) }
    }

    func delete(at offsets: IndexSet) {
        let ids = offsets.map { meetings[$0].id }
        meetings.remove(atOffsets: offsets)
        save()
        Task {
            for id in ids {
                await syncService.deleteMeeting(id: id)
            }
        }
    }

    func syncWithCloud() async {
        await syncService.sync(store: self)
    }

    func search(query: String) -> [Meeting] {
        guard !query.isEmpty else { return meetings }
        let lowercased = query.lowercased()
        return meetings.filter { meeting in
            meeting.title.lowercased().contains(lowercased)
            || meeting.transcriptionText?.lowercased().contains(lowercased) == true
            || meeting.summary?.rawText.lowercased().contains(lowercased) == true
            || meeting.participants.contains { $0.lowercased().contains(lowercased) }
            || meeting.location.lowercased().contains(lowercased)
        }
    }

    func meetingsThisMonth() -> Int {
        let calendar = Calendar.current
        let now = Date()
        return meetings.filter {
            calendar.isDate($0.createdAt, equalTo: now, toGranularity: .month)
        }.count
    }

    #if DEBUG
    func loadSampleData() {
        let cal = Calendar.current
        let now = Date()

        var s1 = MeetingSummary(rawText: "【議題】スプリント進捗確認・来週の計画・リリーススケジュール\n\n【議論内容】API開発は順調に進行中。認証APIが完了し、データ同期に着手予定。フロントエンドはログイン・ホーム画面が完成。デザインは全画面カンプとアセット書き出しが完了。\n\n【決定事項】来週水曜にα版の社内テストを実施。デザインレビューは金曜に設定。\n\n【アクション】佐藤: データ同期API実装(2/19) / 鈴木: 設定画面UI(2/20) / 高橋: アイコン最終版(2/18)")
        s1.agenda = ["スプリント進捗確認", "来週の計画", "リリーススケジュール"]
        s1.discussion = "API開発は順調に進行中。認証APIが完了し、データ同期に着手予定。フロントエンドはログイン・ホーム画面が完成、来週は設定画面に着手。デザインは全画面カンプとアセット書き出しが完了。"
        s1.decisions = ["来週水曜にα版の社内テストを実施", "デザインレビューは金曜に設定"]
        s1.actionItems = [
            ActionItem(assignee: "佐藤", task: "データ同期API実装", deadline: "2/19"),
            ActionItem(assignee: "鈴木", task: "設定画面UI実装", deadline: "2/20"),
            ActionItem(assignee: "高橋", task: "アプリアイコン最終版提出", deadline: "2/18")
        ]

        var s2 = MeetingSummary(rawText: "【テーマ】AIを活用した業務効率化\n\n【アイデア】\n1. 議事録自動生成アプリ（優先度: 高）\n2. 社内ナレッジ検索AI（優先度: 中）\n3. タスク自動振り分け（優先度: 中）\n\n【ネクストステップ】技術検証2週間 / 競合調査レポート / 事業計画ドラフト")
        s2.theme = "AIを活用した業務効率化"
        s2.ideas = [
            IdeaItem(idea: "議事録自動生成アプリ（ローカルAI処理でプライバシー重視）", priority: "高"),
            IdeaItem(idea: "社内ナレッジ検索AI（過去の議事録から情報を検索）", priority: "中"),
            IdeaItem(idea: "タスク自動振り分けシステム（決定事項から自動でタスク作成）", priority: "中")
        ]
        s2.nextSteps = ["議事録自動生成の技術検証を2週間で実施", "競合調査レポートを作成", "事業計画のドラフトを次回ミーティングまでに準備"]

        var s3 = MeetingSummary(rawText: "【顧客】A社（伊藤部長・松本課長）\n\n【ヒアリング】会議後の議事録作成に毎回30分以上。月100回以上の会議で工数削減が課題。セキュリティポリシーが厳しい。\n\n【提案】Standardプラン導入 / 2週間無料トライアル / 管理ダッシュボード検討\n\n【フォローアップ】2/21までに見積書送付")
        s3.customerName = "A社（伊藤部長・松本課長）"
        s3.hearingNotes = "現在は会議後に手動で議事録作成（毎回30分以上）。全社で月100回以上の会議があり、工数削減が課題。セキュリティポリシーが厳しく、外部サーバーへのデータ送信は不可。"
        s3.proposals = ["Standardプランの導入（月額480円/ユーザー）", "2週間の無料トライアル提供", "管理者向けのデータ管理ダッシュボード追加を検討"]
        s3.followUpDeadline = "2/21"

        var s4 = MeetingSummary(rawText: "【要点】フロントエンド実装は順調 / テストの書き方を学びたい / バックエンドにも興味\n\n【次回アクション】来週の勉強会でテスト取り上げ / バックエンド参考資料を共有")
        s4.keyPoints = ["フロントエンド実装は順調", "テストの書き方を学びたい", "バックエンドの知識も身につけたい"]
        s4.nextActions = ["来週の勉強会でテストを取り上げる", "バックエンド入門の参考資料を共有する"]

        meetings = [
            Meeting(
                title: "週次プロジェクト定例",
                date: cal.date(byAdding: .hour, value: -2, to: now)!,
                location: "会議室A",
                participants: ["田中", "佐藤", "鈴木", "高橋"],
                template: .standard,
                status: .completed,
                audioDuration: 2520,
                transcriptionText: "田中です。今週のスプリントの進捗を確認しましょう。佐藤さん、API開発の状況を教えてください。佐藤です。認証APIの実装が完了しました。テストも通っています。次はデータ同期のエンドポイントに取りかかります。鈴木さん、フロントエンドはいかがですか。鈴木です。ログイン画面とホーム画面のUIが完成しました。来週は設定画面を進めます。高橋さん、デザインの件は。高橋です。全画面のデザインカンプが完了しています。アイコンのアセットも書き出し済みです。",
                summary: s1
            ),
            Meeting(
                title: "新規事業ブレスト",
                date: cal.date(byAdding: .day, value: -1, to: now)!,
                location: "オンライン（Zoom）",
                participants: ["山田", "中村", "小林"],
                template: .brainstorm,
                status: .completed,
                audioDuration: 3600,
                transcriptionText: "山田です。今日は新規事業のアイデア出しをしましょう。テーマはAIを活用した業務効率化です。中村さん、何かアイデアありますか。中村です。議事録の自動生成はどうでしょう。会議を録音して、AIで文字起こしと要約を自動でやるサービスです。小林です。それ面白いですね。既存サービスとの差別化はどう考えますか。中村です。ローカル処理でプライバシーを守る点が差別化になると思います。",
                summary: s2
            ),
            Meeting(
                title: "クライアントA社 商談",
                date: cal.date(byAdding: .day, value: -3, to: now)!,
                location: "A社 本社ビル 5F",
                participants: ["木村", "渡辺", "伊藤部長", "松本課長"],
                template: .sales,
                status: .completed,
                audioDuration: 1800,
                transcriptionText: "本日はお時間いただきありがとうございます。弊社の議事録自動生成サービスについてご紹介させていただきます。伊藤です。よろしくお願いします。現在、会議後の議事録作成に毎回30分以上かかっていて困っています。木村です。まさにその課題を解決するサービスです。会議を録音するだけで、AIが自動的に文字起こしと要約を生成します。",
                summary: s3
            ),
            Meeting(
                title: "1on1 ミーティング",
                date: cal.date(byAdding: .day, value: -5, to: now)!,
                location: "カフェスペース",
                participants: ["田中", "鈴木"],
                template: .simple,
                status: .completed,
                audioDuration: 1200,
                transcriptionText: "鈴木さん、最近の仕事の調子はどうですか。鈴木です。フロントエンドの実装は楽しくやれています。ただ、テストの書き方にまだ慣れていなくて、もう少し勉強したいです。いいですね。テストに関しては来週の勉強会で取り上げましょう。他に困っていることはありますか。特にないですが、もう少しバックエンドの知識も付けたいと思っています。",
                summary: s4
            ),
            Meeting(
                title: "デザインレビュー",
                date: cal.date(byAdding: .day, value: -7, to: now)!,
                location: "会議室B",
                participants: ["高橋", "田中", "佐藤"],
                template: .standard,
                status: .readyForSummary,
                audioDuration: 900,
                transcriptionText: "高橋です。今日はアプリのデザインレビューをお願いします。まずホーム画面ですが、議事録の一覧を日付順に表示しています。各項目にはテンプレートのアイコンとステータスバッジを付けました。田中です。全体的にすっきりしていていいですね。録音ボタンはもう少し目立たせた方がいいかもしれません。佐藤です。色使いがいいですね。ダークモードの対応も考えていますか。高橋です。はい、ダークモードは次のフェーズで対応予定です。"
            ),
        ]
        save()
    }
    #endif
}
