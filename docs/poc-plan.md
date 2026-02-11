# 技術検証（PoC）計画書

## 検証目的

WhisperKit + 話者識別 のiOS上での日本語文字起こし精度・処理速度・実用性を検証する。

---

## 重要な発見事項

### SpeakerKit（話者識別）のコスト問題

| プラン | 費用 | 話者識別 |
|--------|------|:--------:|
| Basic（無料） | $0 | **非対応** |
| Pro | **$1,330/月〜**（$1.33/デバイス/月、最低1,000ライセンス） | 対応 |

SpeakerKit Proは最低月額$1,330（約20万円）が必要。個人開発・スタートアップには大きなコスト。

### 代替案

| 方式 | コスト | 精度 | 実装難度 |
|------|--------|:----:|:--------:|
| **SpeakerKit Pro** | $1,330/月〜 | ◎ | 低 |
| **Pyannote（サーバーサイド）** | GPU費用（$50〜100/月） | ◎ | 中 |
| **WhisperX（OSSの話者分離）** | 無料（サーバー費用のみ） | ◯ | 中 |
| **Apple SpeechAnalyzer + 独自実装** | 無料 | △ | 高 |
| **話者識別なし（v1.0）** | 無料 | - | - |

**推奨**: PoC Phase 1ではSpeakerKit Pro 14日間トライアル（$14）で検証し、本番ではコストに応じて判断。話者識別はv1.1以降に後回しにすることも選択肢。

---

## PoC検証フェーズ

### Phase 1: WhisperKit単体（1〜2日）

**目的**: 日本語文字起こしの精度と速度を検証

**手順**:
1. Xcodeプロジェクト作成、WhisperKit SPMで導入
2. tinyモデルで動作確認（軽量テスト）
3. large-v3-turboモデルで日本語精度検証

**検証項目**:
- [ ] 日本語文字起こし精度（静かな環境）
- [ ] 日本語文字起こし精度（会議室環境: 複数人、エアコン音あり）
- [ ] 処理速度（10分音声の処理時間）
- [ ] ハルシネーション発生頻度
- [ ] メモリ使用量
- [ ] バッテリー消費

**最小コード**:
```swift
import WhisperKit

let config = WhisperKitConfig(model: "large-v3-turbo")
let pipe = try await WhisperKit(config)
let result = try await pipe.transcribe(audioPath: "meeting.wav")
print(result?.text ?? "")
```

**必要なInfo.plist**:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>音声の録音と文字起こしのためにマイクへのアクセスが必要です</string>
```

---

### Phase 2: Kotoba-Whisper検証（1〜2日）

**目的**: 日本語特化モデルの精度とlarge-v3-turboとの比較

**手順**:
1. whisperkittoolsでKotoba-Whisper V1.0をCoreML形式に変換
2. WhisperKitにカスタムモデルとして読み込み
3. 同一音声でlarge-v3-turboと比較

**変換コマンド**:
```bash
pip install whisperkittools
whisperkit-generate-model \
    --model-version kotoba-tech/kotoba-whisper-v1.0 \
    --output-dir ./output
```

**検証項目**:
- [ ] CoreML変換が正常に完了するか
- [ ] WhisperKitで正常に読み込めるか
- [ ] large-v3-turbo vs Kotoba-Whisper の日本語精度比較
- [ ] 処理速度比較（Kotoba-Whisperはlarge-v3の6.3倍速と報告）

---

### Phase 3: 話者識別（2〜3日）

**目的**: 話者識別の実現方法と精度を検証

**Option A: SpeakerKit Pro トライアル**
- 14日間トライアル（$14）で検証
- WhisperKit + SpeakerKit統合で「誰が何を話したか」を出力

```swift
import Argmax

let speakerKit = SpeakerKitPro(config: SpeakerKitProConfig())
let audioArray = try AudioProcessor.loadAudioAsFloatArray(fromPath: "audio.wav")
try await speakerKit.initializeDiarization(audioArray: audioArray)
try await speakerKit.processSpeakerSegment(audioArray: audioArray)
let options = DiarizationOptions(numberOfSpeakers: nil) // 自動検出
try await speakerKit.diarize(options: options)
let rttm = speakerKit.generateRTTM()
```

**Option B: Pyannote（サーバーサイド）**
- Python + pyannote.audio をSupabase Edge Functionまたは別サーバーで実行
- 音声データをサーバーに送信する必要あり（プライバシーのトレードオフ）

**検証項目**:
- [ ] 2〜5人の会話での話者識別精度
- [ ] 日本語での識別精度（英語との差）
- [ ] 処理速度（10分音声）
- [ ] SpeakerKit Proのコスト対効果

---

### Phase 4: Apple Watch連携（2〜3日）

**目的**: Watch録音→iPhone転送→文字起こしのフロー検証

**watchOS側 最小実装**:
```swift
import AVFoundation
import WatchConnectivity

// 録音設定（Whisper推奨: 16kHz, 1ch, PCM）
let settings: [String: Any] = [
    AVFormatIDKey: Int(kAudioFormatLinearPCM),
    AVSampleRateKey: 16000.0,
    AVNumberOfChannelsKey: 1,
    AVLinearPCMBitDepthKey: 16
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
    // 受信したファイルでWhisperKit文字起こし開始
    Task {
        let result = try await pipe.transcribe(audioPath: file.fileURL.path)
    }
}
```

**検証項目**:
- [ ] Watch→iPhone ファイル転送の成功率・速度
- [ ] Watchのフォアグラウンド録音の安定性
- [ ] バックグラウンド録音の実現可否（Extended Runtime Session）
- [ ] 30分録音時のWatch側ストレージ・バッテリー影響
- [ ] 録音音質（Watchマイク vs iPhoneマイク）

---

### Phase 5: GLM-4.7-Flash 要約検証（1日）

**目的**: 文字起こしテキスト→議事録要約の品質検証

**検証項目**:
- [ ] テンプレート別（標準/簡易/商談/ブレスト）の要約品質
- [ ] 日本語の自然さ（敬語、文体の統一）
- [ ] アクションアイテムの抽出精度
- [ ] 話者別発言の正しい帰属
- [ ] レスポンス時間
- [ ] JSON構造化出力の安定性

---

## 既知の問題と対策

### 日本語ハルシネーション

| 問題 | 対策 |
|------|------|
| 無音区間で架空テキストが出力される | VAD（Voice Activity Detection）を有効化して無音をフィルタリング |
| 同じフレーズが繰り返される | `no_repeat_ngram_size`を5〜10に設定 |
| CJK言語で特に顕著 | 音声を30秒チャンクに分割して処理 |

### メモリ不足

| 機種 | 推奨モデル |
|------|-----------|
| iPhone 15 Pro以降（6GB+） | large-v3-turbo |
| iPhone 15（6GB） | large-v3-turbo（圧縮版） |
| iPhone 14以前（4GB） | small or medium |

WhisperKitはモデル未指定時にデバイスに最適なモデルを自動選択する機能あり。

### watchOSバックグラウンド録音の制限

- 純粋なバックグラウンド録音はAppleガイドラインで非推奨
- **PoC段階ではフォアグラウンド録音に限定して設計**
- Extended Runtime Session（マインドフルネス）は最大1時間

---

## PoC完了基準

| 項目 | 合格基準 |
|------|---------|
| 日本語文字起こし精度 | WER 10%以下（静かな環境） |
| 処理速度 | 60分音声 → 10分以内（iPhone 15 Pro） |
| 話者識別 | 3人会話で80%以上の正答率 |
| Watch転送 | 30分録音の転送成功率95%以上 |
| AI要約品質 | 人手評価で「実用的」と判断 |
| 全体フロー | 録音→文字起こし→要約→PDF出力が通しで動作 |

---

## 必要機材・費用

| 項目 | 費用 |
|------|------|
| Apple Developer Program | $99/年（既存なら不要） |
| SpeakerKit Pro トライアル | $14 |
| iPhone 15 Pro以降（検証用） | 手持ちがあれば不要 |
| Apple Watch（検証用） | 手持ちがあれば不要 |
| Mac（Xcode開発） | 手持ちがあれば不要 |
