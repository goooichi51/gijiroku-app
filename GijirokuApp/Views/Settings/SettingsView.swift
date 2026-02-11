import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        List {
            Section("アカウント") {
                HStack {
                    Text("プラン")
                    Spacer()
                    Text("Free")
                        .foregroundColor(.secondary)
                }
            }

            Section("議事録設定") {
                NavigationLink("デフォルトテンプレート") {
                    DefaultTemplateSettingView()
                }
            }

            Section("AI設定") {
                NavigationLink("モデル管理") {
                    ModelManagementView()
                }
            }

            Section("その他") {
                HStack {
                    Text("バージョン")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Button("ログアウト", role: .destructive) {
                    Task { await authService.signOut() }
                }
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DefaultTemplateSettingView: View {
    @AppStorage("defaultTemplate") private var defaultTemplate = MeetingTemplate.standard.rawValue

    var body: some View {
        List {
            ForEach(MeetingTemplate.allCases) { template in
                Button {
                    defaultTemplate = template.rawValue
                } label: {
                    HStack {
                        Image(systemName: template.icon)
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text(template.displayName)
                            Text(template.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if defaultTemplate == template.rawValue {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
        }
        .navigationTitle("デフォルトテンプレート")
    }
}
