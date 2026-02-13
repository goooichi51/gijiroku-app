import StoreKit

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    static let standardMonthlyID = "com.gijiroku.app.standard.monthly"

    private var transactionListener: Task<Void, Error>?

    private init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    var standardProduct: Product? {
        products.first { $0.id == Self.standardMonthlyID }
    }

    var isStandardPlan: Bool {
        purchasedProductIDs.contains(Self.standardMonthlyID)
    }

    // MARK: - 商品読み込み

    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let productIDs: Set<String> = [Self.standardMonthlyID]
            products = try await Product.products(for: productIDs)
        } catch {
            errorMessage = "商品情報の取得に失敗しました"
            print("商品取得エラー: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - 購入

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()

        case .userCancelled:
            break

        case .pending:
            errorMessage = "購入処理が保留中です"

        @unknown default:
            errorMessage = "予期しないエラーが発生しました"
        }
    }

    // MARK: - 購入状態の復元

    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchasedProducts()
    }

    // MARK: - 購入済み商品の更新

    func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchased.insert(transaction.productID)
            }
        }

        purchasedProductIDs = purchased

        // PlanManagerと同期
        if purchased.contains(Self.standardMonthlyID) {
            PlanManager.shared.upgradeToPlan(.standard)
        } else {
            PlanManager.shared.upgradeToPlan(.free)
        }
    }

    // MARK: - トランザクション監視

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if let transaction = try? self.checkVerified(result) {
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                }
            }
        }
    }

    // MARK: - 検証

    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Errors

enum StoreError: LocalizedError {
    case failedVerification
    case purchaseFailed(String)

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "購入の検証に失敗しました"
        case .purchaseFailed(let detail):
            return "購入に失敗しました: \(detail)"
        }
    }
}
