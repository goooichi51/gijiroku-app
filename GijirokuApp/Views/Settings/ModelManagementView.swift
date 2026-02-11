import SwiftUI

struct ModelManagementView: View {
    @StateObject private var modelManager = WhisperModelManager()

    var body: some View {
        List {
            Section {
                if let current = modelManager.currentModelName {
                    HStack {
                        Text("現在のモデル")
                        Spacer()
                        Text(current)
                            .foregroundColor(.secondary)
                    }
                }

                if !modelManager.recommendedModel.isEmpty {
                    HStack {
                        Text("推奨モデル")
                        Spacer()
                        Text(modelManager.recommendedModel)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("モデル情報")
            }

            if modelManager.isDownloading {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ダウンロード中...")
                            .font(.subheadline)
                        ProgressView(value: modelManager.downloadProgress)
                            .tint(.blue)
                        Text("\(Int(modelManager.downloadProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                ForEach(modelManager.availableModels, id: \.self) { model in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(model)
                                .font(.body)
                            if model == modelManager.recommendedModel {
                                Text("このデバイスに推奨")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }

                        Spacer()

                        if model == modelManager.currentModelName {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        } else {
                            Button("取得") {
                                Task {
                                    do {
                                        _ = try await modelManager.downloadModel(model)
                                    } catch {
                                        modelManager.errorMessage = error.localizedDescription
                                    }
                                }
                            }
                            .disabled(modelManager.isDownloading)
                        }
                    }
                }
            } header: {
                Text("利用可能なモデル")
            } footer: {
                Text("大きなモデルほど精度が高いですが、処理時間とストレージ容量が増加します。Wi-Fi環境でのダウンロードを推奨します。")
            }

            if let error = modelManager.errorMessage {
                Section {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("モデル管理")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await modelManager.fetchAvailableModels()
        }
    }
}
