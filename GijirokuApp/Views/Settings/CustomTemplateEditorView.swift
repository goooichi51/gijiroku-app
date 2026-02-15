import SwiftUI

struct CustomTemplateEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = CustomTemplateStore.shared

    @State private var name: String
    @State private var icon: String
    @State private var templateDescription: String
    @State private var promptFormat: String
    @State private var showIconPicker = false

    private let existingTemplate: CustomTemplate?
    private let isEditing: Bool

    private static let availableIcons = [
        "doc.text.fill", "list.bullet.clipboard", "chart.bar.doc.horizontal",
        "person.3.fill", "building.2", "phone.fill",
        "video.fill", "desktopcomputer", "globe",
        "star.fill", "flag.fill", "bolt.fill",
        "leaf.fill", "hammer.fill", "wrench.fill",
        "book.fill", "graduationcap.fill", "stethoscope"
    ]

    init(template: CustomTemplate? = nil) {
        self.existingTemplate = template
        self.isEditing = template != nil
        _name = State(initialValue: template?.name ?? "")
        _icon = State(initialValue: template?.icon ?? "doc.text.fill")
        _templateDescription = State(initialValue: template?.templateDescription ?? "")
        _promptFormat = State(initialValue: template?.promptFormat ?? Self.defaultPromptFormat)
    }

    private static let defaultPromptFormat = """
    以下の形式で要約してください:

    【概要】
    会議の概要を2〜3文で記述

    【要点】
    ・要点1
    ・要点2

    【次回アクション】
    ・アクション1
    ・アクション2
    """

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !promptFormat.trimmingCharacters(in: .whitespaces).isEmpty &&
        Self.availableIcons.contains(icon)
    }

    var body: some View {
        Form {
            Section("基本情報") {
                HStack {
                    Text("テンプレート名")
                    Spacer()
                    TextField("例: 週次定例", text: $name)
                        .multilineTextAlignment(.trailing)
                }

                Button {
                    showIconPicker = true
                } label: {
                    HStack {
                        Text("アイコン")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(.teal)
                    }
                }

                HStack {
                    Text("説明")
                    Spacer()
                    TextField("テンプレートの説明", text: $templateDescription)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section {
                TextEditor(text: $promptFormat)
                    .frame(minHeight: 200)
            } header: {
                Text("出力形式の指示")
            } footer: {
                Text("AIに対する出力形式の指示を記述します。テキスト形式で自由に記述してください。")
            }
        }
        .navigationTitle(isEditing ? "テンプレート編集" : "新規テンプレート")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("キャンセル") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    saveTemplate()
                    dismiss()
                }
                .fontWeight(.bold)
                .disabled(!isValid)
            }
        }
        .sheet(isPresented: $showIconPicker) {
            NavigationStack {
                iconPickerView
            }
        }
    }

    private var iconPickerView: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                ForEach(Self.availableIcons, id: \.self) { iconName in
                    Button {
                        icon = iconName
                        showIconPicker = false
                    } label: {
                        Image(systemName: iconName)
                            .font(.title2)
                            .foregroundColor(icon == iconName ? .white : .teal)
                            .frame(width: 48, height: 48)
                            .background(icon == iconName ? Color.teal : Color(.systemGray6))
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("アイコン選択")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完了") { showIconPicker = false }
            }
        }
    }

    private func saveTemplate() {
        if let existing = existingTemplate {
            var updated = existing
            updated.name = name.trimmingCharacters(in: .whitespaces)
            updated.icon = icon
            updated.templateDescription = templateDescription.trimmingCharacters(in: .whitespaces)
            updated.promptFormat = promptFormat
            store.update(updated)
        } else {
            let template = CustomTemplate(
                name: name.trimmingCharacters(in: .whitespaces),
                icon: icon,
                templateDescription: templateDescription.trimmingCharacters(in: .whitespaces),
                promptFormat: promptFormat
            )
            store.add(template)
        }
    }
}
