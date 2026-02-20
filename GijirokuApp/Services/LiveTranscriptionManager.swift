import Foundation
import Accelerate
@preconcurrency import Speech
@preconcurrency import AVFoundation

@MainActor
class LiveTranscriptionManager: ObservableObject {
    @Published var liveText: String = ""
    @Published var isActive = false

    private var analyzer: SpeechAnalyzer?
    private var transcriber: SpeechTranscriber?
    private var transcriptionTask: Task<Void, Never>?
    private var analyzerTask: Task<Void, Never>?
    private var convertTask: Task<Void, Never>?
    private var reservedLocale: Locale?

    func start(inputStream: AsyncStream<AVAudioPCMBuffer>, hardwareFormat: AVAudioFormat) async {
        guard !isActive else { return }

        liveText = ""
        isActive = true

        // ロケール予約
        let locale = Locale.current
        if let supported = await SpeechTranscriber.supportedLocale(equivalentTo: locale) {
            if let reserved = try? await AssetInventory.reserve(locale: supported), reserved {
                reservedLocale = supported
            }
        }

        let transcriber = SpeechTranscriber(
            locale: reservedLocale ?? locale,
            preset: .progressiveTranscription
        )
        self.transcriber = transcriber

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        self.analyzer = analyzer

        // SpeechAnalyzer が対応するフォーマットを取得
        let bestFormat = await SpeechAnalyzer.bestAvailableAudioFormat(
            compatibleWith: [transcriber],
            considering: hardwareFormat
        )
        let targetSampleRate = bestFormat?.sampleRate ?? 16000

        let (analyzerStream, analyzerContinuation) = AsyncStream<AnalyzerInput>.makeStream(
            bufferingPolicy: .bufferingNewest(100)
        )

        // バッファ変換の事前準備（毎回生成を避けてCPU負荷軽減）
        let hwSampleRate = hardwareFormat.sampleRate
        let channelCount = hardwareFormat.channelCount
        let step = max(1, Int(hwSampleRate / targetSampleRate))
        let filter = [Float](repeating: 1.0 / Float(step), count: step)

        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: targetSampleRate,
            channels: channelCount,
            interleaved: false
        ) else { return }

        // バッファ変換タスク：Float32 48kHz → Int16 16kHz（Accelerate/vDSP使用）
        convertTask = Task.detached {
            for await buffer in inputStream {
                guard !Task.isCancelled else { break }
                guard let converted = Self.convertBuffer(
                    buffer,
                    targetFormat: targetFormat,
                    step: step,
                    filter: filter
                ) else { continue }
                analyzerContinuation.yield(AnalyzerInput(buffer: converted))
            }
            analyzerContinuation.finish()
        }

        // アナライザー開始
        analyzerTask = Task {
            do {
                try await analyzer.start(inputSequence: analyzerStream)
            } catch {
                if !Task.isCancelled {
                    AppLogger.transcription.error("リアルタイム文字起こし解析エラー: \(error.localizedDescription)")
                }
            }
        }

        // 結果取得（.progressiveTranscription: 毎回全文が来る）
        transcriptionTask = Task { [weak self] in
            do {
                for try await result in transcriber.results {
                    guard !Task.isCancelled else { break }
                    let text = String(result.text.characters)
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        self?.liveText = text
                    }
                }
            } catch {
                if !Task.isCancelled {
                    AppLogger.transcription.error("リアルタイム文字起こしエラー: \(error.localizedDescription)")
                }
            }
            self?.isActive = false
        }
    }

    func stop() {
        isActive = false
        convertTask?.cancel()
        convertTask = nil
        transcriptionTask?.cancel()
        transcriptionTask = nil
        analyzerTask?.cancel()
        analyzerTask = nil

        let analyzerToStop = analyzer
        analyzer = nil
        transcriber = nil
        if let analyzerToStop {
            Task { await analyzerToStop.cancelAndFinishNow() }
        }

        if let locale = reservedLocale {
            Task { _ = await AssetInventory.release(reservedLocale: locale) }
            reservedLocale = nil
        }
    }

    /// Float32 → Int16 ダウンサンプリング（Accelerate/vDSP使用）
    private static nonisolated func convertBuffer(
        _ buffer: AVAudioPCMBuffer,
        targetFormat: AVAudioFormat,
        step: Int,
        filter: [Float]
    ) -> AVAudioPCMBuffer? {
        guard let floatData = buffer.floatChannelData else { return nil }

        let sourceFrames = Int(buffer.frameLength)
        guard sourceFrames > 0 else { return nil }

        let targetFrames = sourceFrames / step
        guard targetFrames > 0 else { return nil }

        guard let int16Buffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: AVAudioFrameCount(targetFrames)
        ) else { return nil }

        int16Buffer.frameLength = AVAudioFrameCount(targetFrames)

        let channels = Int(targetFormat.channelCount)

        for ch in 0..<channels {
            let src = floatData[ch]
            let dst = int16Buffer.int16ChannelData![ch]

            var decimated = [Float](repeating: 0, count: targetFrames)

            // vDSP_desamp: デシメーション+FIRフィルタ（平均化アンチエイリアシング）
            vDSP_desamp(src, vDSP_Stride(step), filter, &decimated,
                        vDSP_Length(targetFrames), vDSP_Length(step))

            // [-1, 1] クランプ → Int16 スケーリング → 型変換
            var lo: Float = -1.0
            var hi: Float = 1.0
            var scale: Float = Float(Int16.max)
            decimated.withUnsafeMutableBufferPointer { ptr in
                let base = ptr.baseAddress!
                vDSP_vclip(base, 1, &lo, &hi, base, 1, vDSP_Length(targetFrames))
                vDSP_vsmul(base, 1, &scale, base, 1, vDSP_Length(targetFrames))
                vDSP_vfix16(base, 1, dst, 1, vDSP_Length(targetFrames))
            }
        }

        return int16Buffer
    }
}
