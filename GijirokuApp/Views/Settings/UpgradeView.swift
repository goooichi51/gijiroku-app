import SwiftUI

struct UpgradeView: View {
    @ObservedObject private var storeManager = StoreKitManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // ヘッダー
                VStack(spacing: 12) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("Standardプラン")
                        .font(.title2)
                        .fontWeight(.bold)

                    if let product = storeManager.standardProduct {
                        Text("\(product.displayPrice) / 月")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.top, 20)

                // 機能一覧
                VStack(alignment: .leading, spacing: 16) {
                    featureRow(
                        icon: "infinity",
                        title: "録音回数 無制限",
                        description: "Freeプランの月5回制限なし"
                    )
                    featureRow(
                        icon: "wand.and.stars",
                        title: "AI議事録生成",
                        description: "文字起こしからAIが自動で議事録を作成"
                    )
                    featureRow(
                        icon: "doc.text",
                        title: "PDF出力・共有",
                        description: "議事録をPDFにしてLINE等で共有"
                    )
                    featureRow(
                        icon: "rectangle.grid.2x2",
                        title: "全テンプレート",
                        description: "標準・簡易・商談・ブレスト"
                    )
                    featureRow(
                        icon: "timer",
                        title: "録音時間 最大4時間",
                        description: "Freeプランは30分まで"
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)

                // 購入ボタン
                if let product = storeManager.standardProduct {
                    Button {
                        Task {
                            isPurchasing = true
                            do {
                                try await storeManager.purchase(product)
                                if storeManager.isStandardPlan {
                                    dismiss()
                                }
                            } catch {
                                storeManager.errorMessage = error.localizedDescription
                            }
                            isPurchasing = false
                        }
                    } label: {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("Standardプランに登録")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isPurchasing)
                } else if storeManager.isLoading {
                    ProgressView("読み込み中...")
                } else {
                    Text("商品情報を取得できませんでした")
                        .foregroundColor(.secondary)

                    Button("再読み込み") {
                        Task { await storeManager.loadProducts() }
                    }
                }

                // 購入復元
                Button("以前の購入を復元") {
                    Task { await storeManager.restorePurchases() }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)

                if let error = storeManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                // 注意書き
                Text("サブスクリプションは自動更新されます。解約はApple IDの設定から行えます。")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("プランアップグレード")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
