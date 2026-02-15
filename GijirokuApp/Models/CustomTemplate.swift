import Foundation

struct CustomTemplate: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var icon: String
    var templateDescription: String
    var promptFormat: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        icon: String = "doc.text.fill",
        templateDescription: String = "",
        promptFormat: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.templateDescription = templateDescription
        self.promptFormat = promptFormat
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
