import Foundation
import Supabase

@MainActor
class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var errorMessage: String?

    private var client: SupabaseClient { SupabaseManager.shared.client }

    func restoreSession() async {
        isLoading = true
        do {
            _ = try await client.auth.session
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }
        isLoading = false
    }

    func signUpWithEmail(email: String, password: String) async {
        errorMessage = nil
        do {
            try await client.auth.signUp(email: email, password: password)
            isAuthenticated = true
        } catch {
            errorMessage = "アカウント作成に失敗しました: \(error.localizedDescription)"
        }
    }

    func signInWithEmail(email: String, password: String) async {
        errorMessage = nil
        do {
            try await client.auth.signIn(email: email, password: password)
            isAuthenticated = true
        } catch {
            errorMessage = "ログインに失敗しました: \(error.localizedDescription)"
        }
    }

    func signOut() async {
        do {
            try await client.auth.signOut()
            isAuthenticated = false
        } catch {
            errorMessage = "ログアウトに失敗しました: \(error.localizedDescription)"
        }
    }

    func skipAuth() {
        // 開発中: 認証をスキップしてアプリを使用可能にする
        isAuthenticated = true
        isLoading = false
    }
}
