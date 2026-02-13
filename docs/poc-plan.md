# 技術検証（PoC）計画書

## 検証目的

Apple SpeechAnalyzer のiOS上での日本語文字起こし精度・リアルタイム性能・実用性を検証する。

---

## PoC検証フェーズ

### Phase 1: SpeechAnalyzer 日本語文字起こし（1〜2日）

**目的**: SpeechAnalyzer（SpeechTranscriber）の日本語精度と速度を検証

**手順**:
1. Xcodeプロジェクト作成（iOS 26 / Xcode 26）
2. SpeechAnalyzerをimportし、録音した音声で文字起こし
3. リアルタイム文字起こし（ストリーミング）の動作確認

**最小コード（バッチ処理）**:
```swift
import Speech

let transcriber = SpeechTranscriber()
let audioFile = URL(fileURLWithPath: "meeting.m4a")

for await segment in transcriber.transcribe(audioFile) {
    print(segment.text)
}
```

**最小コード（リアルタイム）**:
```swift
import Speech

let transcriber = SpeechTranscriber()

// マイク入力からリアルタイム文字起こし
for await segment in transcriber.transcribe(source: .microphone) {
    print(segment.text)  // リアルタイムで出力
}
```

**必要なInfo.plist**:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>音声の録音と文字起こしのためにマイクへのアクセスが必要です</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>音声をテキストに変換するために音声認識を使用します</string>
```

**検証項目**:
- [ ] 日本語文字起こし精度（静かな環境）
- [ ] 日本語文字起こし精度（会議室環境: 複数人、エアコン音あり）
- [ ] リアルタイム文字起こしのレイテンシ
- [ ] バッチ処理速度（10分音声の処理時間）
- [ ] メモリ使用量
- [ ] バッテリー消費
- [ ] Apple純正ボイスメモの文字起こしとの品質比較

---

### Phase 2: Apple Watch連携（2〜3日）

**目的**: Watch録音→iPhone転送→文字起こしのフロー検証

**watchOS側 最小実装**:
```swift
import AVFoundation
import WatchConnectivity

// 録音設定
let settings: [String: Any] = [
    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
    AVSampleRateKey: 44100.0,
    AVNumberOfChannelsKey: 1
]

// 録音停止後、iPhoneに転送
WCSession.default.transferFile(audioFileURL, metadata: [
    "type": "audio_recording",
    "timestamp": Date().timeIntervalSince1970
])
```

**iPhone側 受信**:
```swift
func session(_ session: WCSession, didReceive file: WCSessionFile) {
    // 受信したファイルでSpeechAnalyzer文字起こし開始
    Task {
        let transcriber = SpeechTranscriber()
        for await segment in transcriber.transcribe(file.fileURL) {
            print(segment.text)
        }
    }
}
```

**検証項目**:
- [ ] Watch→iPhone ファイル転送の成功率・速度
- [ ] Watchのフォアグラウンド録音の安定性
- [ ] バックグラウンド録音の実現可否（HKWorkoutSession方式）
- [ ] 30分録音時のWatch側ストレージ・バッテリー影響
- [ ] 録音音質（Watchマイク vs iPhoneマイク）
- [ ] 30分ごとの継続確認UIの動作確認

---

### Phase 3: Gemini 3 Flash 要約検証（1日）

**目的**: 文字起こしテキスト→議事録要約の品質検証

**検証項目**:
- [ ] テンプレート別（標準/簡易/商談/ブレスト）の要約品質
- [ ] 日本語の自然さ（敬語、文体の統一）
- [ ] アクションアイテムの抽出精度
- [ ] レスポンス時間
- [ ] JSON構造化出力の安定性

---

### Phase 4: 全体フロー結合テスト（1〜2日）

**目的**: 録音→文字起こし→要約→PDF出力の一連のフローが通しで動作することを確認

**検証項目**:
- [ ] iPhone録音 → SpeechAnalyzer文字起こし → Gemini要約 → PDF生成 → 共有
- [ ] Watch録音 → iPhone転送 → SpeechAnalyzer文字起こし → Gemini要約
- [ ] Free/Standard プラン制限の動作確認
- [ ] エラーハンドリング（ネットワーク切断時のAI要約失敗等）

---

## 話者識別について

### 現時点の状況

SpeechAnalyzer単体には話者識別機能がない。MVPでは話者識別なしでリリースし、v1.1以降で対応を検討。

### 将来の選択肢

| 方式 | コスト | 精度 | 実装難度 |
|------|--------|:----:|:--------:|
| **OpenAI gpt-4o-transcribe-diarize** | $0.006/分 | ◎ | 低（API呼び出しのみ） |
| **Pyannote（サーバーサイド）** | GPU費用（$50〜100/月） | ◎ | 中 |
| **SpeakerKit Pro** | $1,330/月〜 | ◎ | 低 |
| **話者識別なし（v1.0）** | 無料 | - | - |

**推奨**: MVPは話者識別なしでリリース。ユーザーからの要望次第で、gpt-4o-transcribe-diarize（$0.006/分、話者分離付き）の導入を検討。

---

## 既知の考慮事項

### SpeechAnalyzerの制約

| 項目 | 内容 |
|------|------|
| カスタム語彙 | 未対応（SFSpeechRecognizerのCustom Language Modelは使えない） |
| 対応OS | iOS 26以降が必須 |
| 日本語WER | 未公開（英語ではWER 14.0%。実機での検証が必要） |
| モデル管理 | OS管理（アプリ側でモデル選択不可） |

### watchOSバックグラウンド録音の制限

- 純粋なバックグラウンド録音はAppleガイドラインで非推奨
- **HKWorkoutSession方式**: 画面消灯後も録音継続可能だが、審査リスクあり
- **PoC段階ではフォアグラウンド録音に限定して設計**

---

## PoC完了基準

| 項目 | 合格基準 |
|------|---------|
| 日本語文字起こし精度 | 実用レベル（Apple純正ボイスメモと同等以上） |
| リアルタイム文字起こし | 録音中にテキストが表示される |
| Watch転送 | 30分録音の転送成功率95%以上 |
| AI要約品質 | 人手評価で「実用的」と判断 |
| 全体フロー | 録音→文字起こし→要約→PDF出力が通しで動作 |

---

## 必要機材・費用

| 項目 | 費用 |
|------|------|
| Apple Developer Program | $99/年（既存なら不要） |
| iPhone（iOS 26対応、iPhone 11以降） | 手持ちがあれば不要 |
| Apple Watch（watchOS 13対応） | 手持ちがあれば不要 |
| Mac（Xcode 26） | 手持ちがあれば不要 |
| **合計** | **$99（既存なら¥0）** |

SpeakerKit Proトライアル（$14）が不要になり、初期検証コストが大幅に削減。
