import Foundation
import WhisperKit

@MainActor
class WhisperModelManager: ObservableObject {
    @Published var availableModels: [String] = []
    @Published var recommendedModel: String = ""
    @Published var currentModelName: String?
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let modelRepo = "argmaxinc/whisperkit-coreml"

    func fetchAvailableModels() async {
        do {
            let models = try await WhisperKit.fetchAvailableModels(from: modelRepo)
            availableModels = models.sorted()

            let recommended = WhisperKit.recommendedModels()
            recommendedModel = recommended.default
            currentModelName = currentModelName ?? recommendedModel
        } catch {
            errorMessage = "モデル一覧の取得に失敗しました: \(error.localizedDescription)"
        }
    }

    @discardableResult
    func downloadModel(_ modelName: String) async throws -> URL {
        isDownloading = true
        downloadProgress = 0
        errorMessage = nil
        defer { isDownloading = false }

        let modelFolder = try await WhisperKit.download(
            variant: modelName,
            from: modelRepo,
            progressCallback: { [weak self] progress in
                Task { @MainActor [weak self] in
                    self?.downloadProgress = progress.fractionCompleted
                }
            }
        )

        currentModelName = modelName
        return modelFolder
    }

    /// デバイスに最適なモデルを取得
    static func recommendedModelForDevice() -> String {
        let recommended = WhisperKit.recommendedModels()
        return recommended.default
    }
}
