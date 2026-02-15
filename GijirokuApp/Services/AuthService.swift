import Foundation
import Supabase
import AuthenticationServices
import CryptoKit

@MainActor
class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var errorMessage: String?

    private var client: SupabaseClient { SupabaseManager.shared.client }
    private var currentNonce: String?

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

    // MARK: - Apple ID ログイン

    func prepareAppleSignIn() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        errorMessage = nil

        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = appleIDCredential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8),
                  let nonce = currentNonce else {
                errorMessage = "Apple IDの認証情報の取得に失敗しました"
                return
            }

            do {
                try await client.auth.signInWithIdToken(
                    credentials: .init(
                        provider: .apple,
                        idToken: tokenString,
                        nonce: nonce
                    )
                )
                isAuthenticated = true
            } catch {
                errorMessage = "Apple IDログインに失敗しました: \(error.localizedDescription)"
            }

        case .failure(let error):
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                return
            }
            errorMessage = "Apple IDログインに失敗しました: \(error.localizedDescription)"
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
        isAuthenticated = true
        isLoading = false
    }

    // MARK: - Nonce生成

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            // SecRandomCopyBytes失敗時のフォールバック
            return (0..<length).map { _ in
                let charset = "0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._"
                return String(charset.randomElement()!)
            }.joined()
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
