import SwiftUI

struct CustomTemplateListView: View {
    @ObservedObject private var store = CustomTemplateStore.shared
    @State private var showEditor = false
    @State private var editingTemplate: CustomTemplate?

    var body: some View {
        List {
            if store.templates.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.badge.plus")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("カスタムテンプレートがありません")
                        .foregroundColor(.secondary)
                    Text("独自の出力形式でAI議事録を生成できます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .listRowBackground(Color.clear)
            }

            ForEach(store.templates) { template in
                Button {
                    editingTemplate = template
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: template.icon)
                            .font(.title3)
                            .foregroundColor(.teal)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(template.templateDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    store.delete(store.templates[index])
                }
            }
        }
        .navigationTitle("カスタムテンプレート")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showEditor = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack {
                CustomTemplateEditorView()
            }
        }
        .sheet(item: $editingTemplate) { template in
            NavigationStack {
                CustomTemplateEditorView(template: template)
            }
        }
    }
}
