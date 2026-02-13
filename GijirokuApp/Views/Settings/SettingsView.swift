import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var meetingStore: MeetingStore
    @ObservedObject private var planManager = PlanManager.shared
    @State private var isSyncing = false

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
            }

            Section("AI設定") {
                NavigationLink("モデル管理") {
                    ModelManagementView()
                }
            }

            Section("データ") {
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
            }

            Section("その他") {
                NavigationLink("プライバシーポリシー") {
                    PrivacyPolicyView()
                }
                NavigationLink("利用規約") {
                    TermsOfServiceView()
                }
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
