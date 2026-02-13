import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    Text("最終更新日: 2026年2月12日")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    section("1. はじめに",
                            "「議事録アプリ」（以下「本アプリ」）は、お客様のプライバシーを尊重し、個人情報の保護に努めます。本プライバシーポリシーは、本アプリが収集・利用する情報について説明します。")

                    section("2. 収集する情報",
                            """
                            本アプリは以下の情報を収集します：

                            ・アカウント情報: メールアドレス、Apple ID（ログイン時）
                            ・音声データ: 録音した音声はお使いの端末内でのみ処理され、外部サーバーには送信されません
                            ・文字起こしテキスト: AI要約機能を利用する場合のみ、文字起こしテキストがサーバーに送信されます
                            ・利用状況: アプリの使用回数、サブスクリプション状態
                            """)

                    section("3. 情報の利用目的",
                            """
                            収集した情報は以下の目的で利用します：

                            ・アカウント認証とサービス提供
                            ・AI議事録要約の生成（テキストデータのみ送信）
                            ・クラウドバックアップと端末間同期
                            ・サービスの改善と不具合の修正
                            """)

                    section("4. 音声データの取り扱い",
                            "録音された音声データは、お使いの端末内でのみ処理・保存されます。音声データが外部サーバーに送信されることはありません。文字起こし処理もすべて端末内のAIモデル（WhisperKit）で行われます。")

                    section("5. 第三者提供",
                            """
                            AI要約機能を利用する場合、文字起こしテキスト（音声データではありません）がGoogle Gemini APIに送信されます。Googleのプライバシーポリシーに従って処理されます。

                            上記以外の目的で個人情報を第三者に提供することはありません。
                            """)

                    section("6. データの保存と削除",
                            "アプリ内のデータはいつでも削除できます。アカウントを削除すると、クラウドに保存されたデータもすべて削除されます。")

                    section("7. お問い合わせ",
                            "プライバシーに関するお問い合わせは、アプリ内のサポート機能またはメールにてご連絡ください。")
                }
            }
            .padding()
        }
        .navigationTitle("プライバシーポリシー")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(body)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    Text("最終更新日: 2026年2月12日")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    section("第1条（適用）",
                            "本利用規約（以下「本規約」）は、「議事録アプリ」（以下「本アプリ」）の利用に関する条件を定めるものです。ユーザーは本規約に同意の上、本アプリを利用するものとします。")

                    section("第2条（サービス内容）",
                            """
                            本アプリは以下のサービスを提供します：

                            ・音声録音機能
                            ・AI文字起こし機能（端末内処理）
                            ・AI議事録要約機能
                            ・PDF出力・共有機能
                            ・クラウドバックアップ
                            """)

                    section("第3条（利用料金）",
                            """
                            ・Freeプラン: 月5回まで、1回30分まで（無料）
                            ・Standardプラン: 月額480円（税込）、無制限

                            Standardプランは自動更新サブスクリプションです。Apple IDの設定画面から解約できます。
                            """)

                    section("第4条（禁止事項）",
                            """
                            ユーザーは以下の行為を行ってはなりません：

                            ・法令に違反する行為
                            ・第三者の権利を侵害する目的での録音
                            ・本アプリの逆コンパイル、改ざん
                            ・サービスの運営を妨害する行為
                            """)

                    section("第5条（免責事項）",
                            "AI文字起こし・AI要約の結果は参考情報です。正確性を保証するものではありません。重要な議事録については内容をご確認ください。")

                    section("第6条（サービスの変更・終了）",
                            "運営者は事前の通知をもって、本アプリのサービス内容を変更、または終了する場合があります。")

                    section("第7条（準拠法）",
                            "本規約は日本法に準拠し、東京地方裁判所を第一審の専属的合意管轄裁判所とします。")
                }
            }
            .padding()
        }
        .navigationTitle("利用規約")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(body)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
