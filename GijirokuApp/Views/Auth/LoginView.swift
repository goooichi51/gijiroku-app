import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()

                // ロゴ
                VStack(spacing: 12) {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.blue)
                        .accessibilityHidden(true)
                    Text("議事録アプリ")
                        .font(.title)
                        .bold()
                }

                // Apple IDログインボタン
                SignInWithAppleButton(.signIn) { request in
                    let hashedNonce = authService.prepareAppleSignIn()
                    request.requestedScopes = [.email, .fullName]
                    request.nonce = hashedNonce
                } onCompletion: { result in
                    Task {
                        await authService.handleAppleSignIn(result: result)
                    }
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 50)
                .cornerRadius(12)
                .padding(.horizontal, 30)
                .accessibilityLabel("Apple IDでサインイン")

                // 区切り線
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(.systemGray4))
                    Text("または")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(.systemGray4))
                }
                .padding(.horizontal, 30)
                .accessibilityHidden(true)

                // メールフォーム
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("メールアドレス", text: $viewModel.email)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)

                        if !viewModel.email.isEmpty && !viewModel.isEmailValid {
                            Text("有効なメールアドレスを入力してください")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        SecureField("パスワード（6文字以上）", text: $viewModel.password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(viewModel.isSignUp ? .newPassword : .password)

                        if viewModel.isSignUp && !viewModel.password.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: viewModel.password.count >= 6 ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(viewModel.password.count >= 6 ? .green : .red)
                                    .font(.caption2)
                                Text("6文字以上")
                                    .font(.caption2)
                                    .foregroundColor(viewModel.password.count >= 6 ? .green : .red)
                            }
                        }
                    }
                }
                .padding(.horizontal, 30)

                // エラー
                if let error = authService.errorMessage {
                    HStack {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                        Button {
                            authService.errorMessage = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.6))
                        }
                        .accessibilityLabel("エラーを閉じる")
                    }
                    .padding(.horizontal)
                }

                // ログイン/登録ボタン
                VStack(spacing: 12) {
                    Button {
                        Task {
                            viewModel.isLoading = true
                            if viewModel.isSignUp {
                                await authService.signUpWithEmail(email: viewModel.email, password: viewModel.password)
                            } else {
                                await authService.signInWithEmail(email: viewModel.email, password: viewModel.password)
                            }
                            viewModel.isLoading = false
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text(viewModel.isSignUp ? "アカウント作成" : "メールでログイン")
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(viewModel.isFormValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                    .padding(.horizontal, 30)

                    Button {
                        viewModel.isSignUp.toggle()
                        authService.errorMessage = nil
                    } label: {
                        Text(viewModel.isSignUp ? "既にアカウントをお持ちの方" : "新規アカウント作成")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }

                // ログインなしで利用
                Button {
                    authService.skipAuth()
                } label: {
                    Text("スキップ（ログインなしで使う）")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
    }
}
