import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var meetingStore: MeetingStore
    @ObservedObject private var planManager = PlanManager.shared
    @State private var isSyncing = false
    @State private var showDeleteRecordingsAlert = false
    @State private var showLogoutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var isDeletingAccount = false
    @AppStorage("syncTranscriptionToCloud") private var syncTranscriptionToCloud = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var storageSize: String {
        let recordings = AudioFileManager.shared.allRecordings()
        let totalBytes = recordings.compactMap { AudioFileManager.shared.fileSize(at: $0) }.reduce(0, +)
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalBytes)
    }

    private func openContactEmail() {
        let subject = "議事録アプリ お問い合わせ (v\(appVersion))"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:support@gijiroku-app.com?subject=\(subject)") {
            UIApplication.shared.open(url)
        }
    }

    var body: some View {
        List {
            Section("プラン") {
                HStack {
                    Text("現在のプラン")
                    Spacer()
                    Text(planManager.currentPlan == .standard ? "Standard" : "Free")
                        .foregroundColor(planManager.currentPlan == .standard ? .blue : .secondary)
                        .fontWeight(.medium)
                }

                if planManager.currentPlan == .free {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("今月の録音回数")
                            Spacer()
                            Text("\(planManager.meetingsThisMonth) / 5")
                                .foregroundColor(.secondary)
                        }

                        ProgressView(value: Double(planManager.meetingsThisMonth), total: 5)
                            .tint(planManager.meetingsThisMonth >= 4 ? .orange : .blue)
                    }

                    NavigationLink {
                        UpgradeView()
                    } label: {
                        HStack {
                            Image(systemName: "star.circle.fill")
                                .foregroundColor(.blue)
                            Text("Standardプランにアップグレード")
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                    }
                }
            }

            Section("議事録設定") {
                NavigationLink("デフォルトテンプレート") {
                    DefaultTemplateSettingView()
                }
                NavigationLink {
                    CustomTemplateListView()
                } label: {
                    HStack {
                        Text("カスタムテンプレート")
                        Spacer()
                        Text("\(CustomTemplateStore.shared.templates.count)")
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section("データ") {
                Toggle(isOn: $syncTranscriptionToCloud) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("文字起こし・要約をクラウドに保存")
                        Text("OFFの場合、端末変更時にテキストデータは引き継がれません")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Button {
                    isSyncing = true
                    Task {
                        await meetingStore.syncWithCloud()
                        isSyncing = false
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("クラウド同期")
                        Spacer()
                        if isSyncing {
                            ProgressView()
                        } else if let lastSync = meetingStore.syncService.lastSyncDate {
                            Text(lastSync, style: .relative)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .disabled(isSyncing)

                if let syncError = meetingStore.syncService.syncError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text(syncError)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section("ストレージ") {
                HStack {
                    Image(systemName: "waveform")
                    Text("録音ファイル")
                    Spacer()
                    Text(storageSize)
                        .foregroundColor(.secondary)
                }

                Button(role: .destructive) {
                    showDeleteRecordingsAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("古い録音ファイルを削除")
                    }
                }
            }

            Section("その他") {
                NavigationLink("プライバシーポリシー") {
                    PrivacyPolicyView()
                }
                NavigationLink("利用規約") {
                    TermsOfServiceView()
                }
                Button {
                    openContactEmail()
                } label: {
                    HStack {
                        Text("お問い合わせ")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                HStack {
                    Text("バージョン")
                    Spacer()
                    Text(appVersion)
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Button("ログアウト", role: .destructive) {
                    showLogoutAlert = true
                }
            }

            #if DEBUG
            Section("デバッグ") {
                Picker("テストプラン", selection: Binding(
                    get: { planManager.currentPlan },
                    set: { planManager.upgradeToPlan($0) }
                )) {
                    Text("Free").tag(SubscriptionPlan.free)
                    Text("Standard").tag(SubscriptionPlan.standard)
                }
                .pickerStyle(.segmented)
            }
            #endif

            Section {
                Button(role: .destructive) {
                    showDeleteAccountAlert = true
                } label: {
                    HStack {
                        if isDeletingAccount {
                            ProgressView()
                                .padding(.trailing, 4)
                        }
                        Text("アカウントを削除")
                    }
                }
                .disabled(isDeletingAccount)
            } footer: {
                Text("アカウントと関連するすべてのデータが完全に削除されます。この操作は取り消せません。")
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
        .alert("ログアウトしますか？", isPresented: $showLogoutAlert) {
            Button("ログアウト", role: .destructive) {
                Task { await authService.signOut() }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("ローカルに保存されたデータは残りますが、クラウド同期には再ログインが必要です。")
        }
        .alert("アカウントを削除しますか？", isPresented: $showDeleteAccountAlert) {
            Button("削除する", role: .destructive) {
                isDeletingAccount = true
                Task {
                    await authService.deleteAccount()
                    isDeletingAccount = false
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("アカウントと関連するすべてのデータが完全に削除されます。この操作は取り消すことができません。")
        }
        .alert("録音ファイルを削除しますか？", isPresented: $showDeleteRecordingsAlert) {
            Button("削除", role: .destructive) {
                AudioFileManager.shared.deleteAllRecordings()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("参照されていない録音ファイルを削除します。議事録のデータは残ります。")
        }
    }
}

struct DefaultTemplateSettingView: View {
    @AppStorage("defaultTemplate") private var defaultTemplate = MeetingTemplate.standard.rawValue
    @ObservedObject private var planManager = PlanManager.shared

    var body: some View {
        List {
            ForEach(MeetingTemplate.allCases) { template in
                let isAvailable = planManager.isTemplateAvailable(template)
                Button {
                    if isAvailable {
                        defaultTemplate = template.rawValue
                    }
                } label: {
                    HStack {
                        Image(systemName: template.icon)
                            .foregroundColor(isAvailable ? .blue : .secondary)
                        VStack(alignment: .leading) {
                            HStack {
                                Text(template.displayName)
                                if !isAvailable {
                                    Image(systemName: "lock.fill")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Text(template.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if defaultTemplate == template.rawValue && isAvailable {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(isAvailable ? .primary : .secondary)
                .disabled(!isAvailable)
            }
        }
        .navigationTitle("デフォルトテンプレート")
    }
}
