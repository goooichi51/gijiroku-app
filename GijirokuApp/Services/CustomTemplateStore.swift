import Foundation

class CustomTemplateStore: ObservableObject {
    static let shared = CustomTemplateStore()

    @Published var templates: [CustomTemplate] = []

    private let storageKey = "customTemplates"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        load()
    }

    func add(_ template: CustomTemplate) {
        templates.append(template)
        save()
    }

    func update(_ template: CustomTemplate) {
        guard let index = templates.firstIndex(where: { $0.id == template.id }) else { return }
        var updated = template
        updated.updatedAt = Date()
        templates[index] = updated
        save()
    }

    func delete(_ template: CustomTemplate) {
        templates.removeAll { $0.id == template.id }
        save()
    }

    func template(for id: UUID) -> CustomTemplate? {
        templates.first { $0.id == id }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(templates) else { return }
        userDefaults.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = userDefaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([CustomTemplate].self, from: data) else { return }
        templates = decoded
    }
}
