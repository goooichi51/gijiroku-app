import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()

                // ロゴ
                VStack(spacing: 12) {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.blue)
                    Text("議事録アプリ")
                        .font(.title)
                        .bold()
                }

                // フォーム
                VStack(spacing: 16) {
                    TextField("メールアドレス", text: $viewModel.email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("パスワード（6文字以上）", text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(viewModel.isSignUp ? .newPassword : .password)
                }
                .padding(.horizontal, 30)

                // エラー
                if let error = authService.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
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
                            Text(viewModel.isSignUp ? "アカウント作成" : "ログイン")
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

                // スキップ（開発用）
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
