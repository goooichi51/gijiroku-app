# 議事録作成アプリ - 開発ガイド

## プロジェクト概要

音声録音 → AI文字起こし（ローカル）→ AI要約 → 議事録PDF出力のiOS + watchOSアプリ。

## 技術スタック

| レイヤー | 技術 |
|----------|------|
| アプリ | **Swift / SwiftUI**（iOS 26+ / watchOS 13+） |
| 文字起こし | **Apple SpeechAnalyzer**（ローカル、iOS 26標準API、追加DL不要） |
| 話者識別 | MVP後に対応検討（SpeechAnalyzer単体では非対応） |
| 課金 | **StoreKit 2**（自動更新サブスクリプション） |
| AI要約 | **Gemini 3 Flash API**（Google） |
| バックエンド | **Supabase**（認証・データ同期・APIキー保護） |
| Watch連携 | **WCSession (transferFile)** |

## プロジェクト構成

```
gijoroku_app_v2/
├── CLAUDE.md                # 本ファイル
├── docs/                    # 計画ドキュメント（変更しない）
│   ├── requirements.md      # 要件定義・競合調査
│   ├── ui-wireframe-spec.md # UI/UXワイヤーフレーム仕様
│   ├── poc-plan.md          # 技術検証計画
│   └── business-plan.md     # 事業計画・収支シミュレーション
├── GijirokuApp/             # Xcodeプロジェクト（iOS）
│   ├── App/                 # アプリエントリポイント
│   ├── Views/               # SwiftUI画面
│   ├── ViewModels/          # ViewModel層
│   ├── Models/              # データモデル
│   ├── Services/            # SpeechAnalyzer, API連携等
│   └── Resources/           # アセット、ローカライズ
├── GijirokuWatch/           # watchOSアプリ
│   ├── Views/               # Watch画面
│   └── Services/            # 録音・転送サービス
└── Supabase/                # Supabase設定・マイグレーション
```

## 開発ルール

### コード規約
- 言語: Swift
- UI: SwiftUI（UIKitは使わない）
- アーキテクチャ: MVVM
- 変数名・関数名: 英語（キャメルケース）
- コメント: 日本語OK（ただし最小限に）
- エラーメッセージ: 日本語で分かりやすく

### Git
- コミットメッセージ: 日本語
- ブランチ名: 英語（feature/xxx, fix/xxx, hotfix/xxx）

### 重要な設計方針
- **音声データは端末外に出さない**（プライバシー最重要）
- **文字起こしは完全ローカル**（Apple SpeechAnalyzer、APIコスト0）
- **AI要約のみサーバー通信**（Gemini 3 Flash、テキストデータのみ送信）
- **APIキーはアプリに埋め込まない**（Supabase Edge Function経由で呼び出し）

### テスト
- ユニットテスト: XCTest
- UIテスト: XCUITest
- テストファイル名: `[対象クラス名]Tests.swift`

## 主要機能（MVP）

| 機能 | 詳細 |
|------|------|
| 音声録音 | iPhone / Apple Watch（最大4時間、Watch は30分毎に継続確認） |
| AI文字起こし | Apple SpeechAnalyzer（ローカル処理、追加DL不要） |
| 話者識別 | MVP後に対応検討 |
| AI議事録要約 | Gemini 3 Flash API → テンプレート別出力（標準/簡易/商談/ブレスト） |
| PDF出力 | A4フォーマット、iOS共有シートで共有 |
| 認証 | Apple ID / メール（Supabase Auth） |

## 料金プラン

| プラン | 内容 |
|--------|------|
| Free | 月5回・1回30分、AI要約なし、簡易メモのみ |
| Standard ¥480/月 | 無制限、AI要約、全テンプレート、PDF、話者識別 |

## Supabase

- **プロジェクト**: gijiroku-app
- **リージョン**: ap-northeast-1（東京）
- **URL**: `https://mbhcyaocfngegssvtdgl.supabase.co`
- **Edge Function**: `summarize`（Gemini 3 Flash API呼び出し）
- **テーブル**: `profiles`, `meetings`（RLS有効）

## ドキュメント参照

設計判断に迷ったときは docs/ 配下のドキュメントを参照:
- 機能仕様・優先度 → `docs/requirements.md`
- 画面レイアウト・フロー → `docs/ui-wireframe-spec.md`
- 技術的な懸念事項 → `docs/poc-plan.md`（SpeechAnalyzerの制約・話者識別の将来方針）
- App Store申請 → `docs/appstore-metadata.md`
