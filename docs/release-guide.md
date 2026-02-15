# App Store リリース手順ガイド

## 前提条件

- Apple Developer Program に加入済み（年額 ¥15,800）
- Xcode がインストール済み
- Supabase CLI がインストール済み（`brew install supabase/tap/supabase`）

---

## ステップ1: Supabase バックエンド設定

### 1-1. Supabase CLI にログイン

```bash
supabase login
```

ブラウザが開くので、Supabase アカウントでログイン。

### 1-2. DB マイグレーション適用

```bash
cd /Users/goooichi51/dev/claudecode/gijoroku_app_v2

# プロジェクトをリンク
supabase link --project-ref mbhcyaocfngegssvtdgl

# マイグレーション適用
supabase db push
```

適用されるマイグレーション:
1. `20260211000000_create_meetings.sql` — profiles + meetings テーブル作成
2. `20260215000000_add_transcription_segments.sql` — transcription_segments_json カラム追加
3. `20260215100000_add_custom_template_id.sql` — custom_template_id カラム追加
4. `20260215110000_fix_meeting_status_default.sql` — ステータスデフォルト値修正

### 1-3. GEMINI_API_KEY を秘密値として登録

```bash
supabase secrets set GEMINI_API_KEY=your-gemini-api-key --project-ref mbhcyaocfngegssvtdgl
```

> Google AI Studio (https://aistudio.google.com/apikey) で API キーを取得

### 1-4. Edge Function デプロイ

```bash
supabase functions deploy summarize --project-ref mbhcyaocfngegssvtdgl
```

### 1-5. 動作確認

```bash
# Edge Function のステータス確認
supabase functions list --project-ref mbhcyaocfngegssvtdgl
```

---

## ステップ2: Apple Developer Portal 設定

### 2-1. App ID 作成

1. [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/list) にアクセス
2. 「Identifiers」→「+」ボタン
3. 「App IDs」を選択 → 「App」を選択
4. 以下を入力:
   - **Description**: GijirokuApp
   - **Bundle ID**: `com.gijiroku.app`（Explicit）
5. Capabilities で以下を有効化:
   - Sign In with Apple
   - In-App Purchase
6. 「Continue」→「Register」

watchOS 用も同様に作成:
- **Bundle ID**: `com.gijiroku.watch`

### 2-2. Provisioning Profile 生成

Xcode の Automatically manage signing を使用するため、手動作成は不要。
Xcode で初回ビルド時に自動生成される。

---

## ステップ3: App Store Connect 設定

### 3-1. アプリ登録

1. [App Store Connect](https://appstoreconnect.apple.com) にアクセス
2. 「マイApp」→「+」→「新規App」
3. 以下を入力:
   - **プラットフォーム**: iOS
   - **名前**: 議事録アプリ - AI文字起こし&要約
   - **プライマリ言語**: 日本語
   - **バンドルID**: com.gijiroku.app
   - **SKU**: gijiroku-app
4. 「作成」

### 3-2. アプリ情報入力

`docs/appstore-metadata.md` の内容を転記:

| 項目 | 内容 |
|------|------|
| サブタイトル | 録音するだけでAIが議事録を作成 |
| カテゴリ | ビジネス（プライマリ）、仕事効率化（セカンダリ） |
| 年齢制限 | 4+ |
| 価格 | 無料（アプリ内課金あり） |

### 3-3. サブスクリプション商品登録

1. App Store Connect → 「サブスクリプション」
2. 「サブスクリプショングループ」を作成:
   - **グループ名**: Gijiroku Premium
3. サブスクリプションを追加:
   - **商品ID**: `com.gijiroku.app.standard.monthly`
   - **参照名**: Standard Monthly
   - **期間**: 1ヶ月
   - **価格**: ¥480
4. ローカライゼーション（日本語）:
   - **表示名**: Standardプラン
   - **説明**: 無制限録音、AI議事録生成、全テンプレート、PDF出力

### 3-4. スクリーンショットアップロード

`screenshots/` フォルダに10枚準備済み。
App Store Connect の「メディア」セクションにアップロード。

必要なサイズ:
- iPhone 6.9インチ（iPhone 16 Pro Max）: 1320 × 2868 px
- iPhone 6.7インチ（iPhone 15 Plus）: 1290 × 2796 px
- iPad 13インチ（任意）

### 3-5. プライバシー設問への回答

App Store Connect → 「Appのプライバシー」

**収集するデータ:**

| データタイプ | 用途 | ユーザーに紐付け |
|-------------|------|-----------------|
| メールアドレス | アカウント認証 | はい |
| ユーザーID | アプリ機能 | はい |
| 購入履歴 | アプリ機能 | はい |

**収集しないデータ:**
- 位置情報
- 連絡先
- 閲覧履歴
- 検索履歴
- 診断データ

> 音声データは端末内で処理され、サーバーには送信されない旨を明記

### 3-6. 審査用情報

**デモアカウント（作成済み）:**
- メールアドレス: test@example.com
- パスワード: TestPass1234

**審査員へのメモ:**
```
このアプリは会議の録音からAI議事録を自動生成するアプリです。

テスト方法:
1. デモアカウントでログイン
2. 「録音」タブで音声を録音（30秒程度でOK）
3. 録音完了後、テンプレートを選択して議事録を作成
4. 「AI議事録生成」ボタンで要約を生成
5. PDF出力・共有が可能

音声認識はデバイス上で完全にローカル処理されます。
AI要約のみ、テキストデータをサーバーに送信します。
```

---

## ステップ4: デモアカウント作成

### Supabase ダッシュボードで作成

1. [Supabase Dashboard](https://supabase.com/dashboard/project/mbhcyaocfngegssvtdgl) にアクセス
2. Authentication → Users → 「Add user」
3. 以下で作成:
   - **Email**: test@example.com
   - **Password**: Test1234!
   - **Auto Confirm**: ON

---

## ステップ5: ビルド＆提出

### 5-1. Signing 設定

1. Xcode でプロジェクトを開く
2. GijirokuApp ターゲット → Signing & Capabilities
3. Team を選択（Apple Developer アカウント）
4. GijirokuWatch も同様に設定

### 5-2. Archive 作成

```bash
# Xcode GUI から
Product → Archive

# または CLI から
xcodebuild archive \
  -scheme GijirokuApp \
  -archivePath build/GijirokuApp.xcarchive \
  -destination 'generic/platform=iOS'
```

### 5-3. App Store Connect にアップロード

1. Xcode Organizer を開く（Window → Organizer）
2. 作成した Archive を選択
3. 「Distribute App」→「App Store Connect」
4. 「Upload」を選択
5. 完了を待つ

### 5-4. TestFlight テスト（推奨）

1. App Store Connect で「TestFlight」タブを確認
2. 内部テスターを追加してテスト
3. 問題なければ「審査に提出」

---

## ステップ6: 審査提出

1. App Store Connect → 該当バージョン
2. ビルドを選択（アップロードしたもの）
3. 全ての情報が入力されていることを確認
4. 「審査に提出」をクリック

**審査期間**: 通常 24〜48 時間

---

## チェックリスト

### コード側（完了済み）
- [x] PrivacyInfo.xcprivacy 作成
- [x] プライバシーポリシー・利用規約の UI 実装
- [x] Info.plist 権限説明文（マイク、音声認識）
- [x] エンタイトルメント（Sign in with Apple、In-App Purchases）
- [x] アプリアイコン（1024x1024）
- [x] StoreKit 2 実装
- [x] 98 テスト全通過
- [x] DB マイグレーション SQL 準備

### Supabase（完了済み）
- [x] `supabase login` でCLI認証
- [x] `supabase link` でプロジェクトリンク
- [x] `supabase db push` でマイグレーション適用（4ファイル）
- [x] GEMINI_API_KEY 登録済み
- [x] `supabase functions deploy summarize` でEdge Functionデプロイ（v5）
- [x] デモアカウント作成（test@example.com / TestPass1234）

### Apple Developer（要実行）
- [ ] App ID 作成（com.gijiroku.app, com.gijiroku.watch）
- [ ] App Store Connect でアプリ登録
- [ ] サブスクリプション商品登録（com.gijiroku.app.standard.monthly）
- [ ] スクリーンショットアップロード
- [ ] プライバシー設問回答
- [ ] 審査用情報入力
- [ ] Archive → アップロード → 審査提出
