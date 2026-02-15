import XCTest
@testable import GijirokuApp

final class CustomTemplateStoreTests: XCTestCase {

    private var store: CustomTemplateStore!
    private var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "CustomTemplateStoreTests")!
        testDefaults.removePersistentDomain(forName: "CustomTemplateStoreTests")
        store = CustomTemplateStore(userDefaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "CustomTemplateStoreTests")
        testDefaults = nil
        store = nil
        super.tearDown()
    }

    // MARK: - 初期状態

    func testInitialStateIsEmpty() {
        XCTAssertTrue(store.templates.isEmpty)
    }

    // MARK: - 追加

    func testAddTemplate() {
        let template = CustomTemplate(
            name: "テスト",
            icon: "star.fill",
            templateDescription: "テスト説明",
            promptFormat: "テストプロンプト"
        )
        store.add(template)

        XCTAssertEqual(store.templates.count, 1)
        XCTAssertEqual(store.templates[0].name, "テスト")
        XCTAssertEqual(store.templates[0].icon, "star.fill")
    }

    func testAddMultipleTemplates() {
        let t1 = CustomTemplate(name: "テンプレ1", promptFormat: "p1")
        let t2 = CustomTemplate(name: "テンプレ2", promptFormat: "p2")
        store.add(t1)
        store.add(t2)

        XCTAssertEqual(store.templates.count, 2)
    }

    // MARK: - 更新

    func testUpdateTemplate() {
        let template = CustomTemplate(name: "元の名前", promptFormat: "元のプロンプト")
        store.add(template)

        var updated = template
        updated.name = "新しい名前"
        store.update(updated)

        XCTAssertEqual(store.templates.count, 1)
        XCTAssertEqual(store.templates[0].name, "新しい名前")
    }

    func testUpdateSetsUpdatedAt() {
        let template = CustomTemplate(name: "テスト", promptFormat: "p")
        store.add(template)
        let originalDate = store.templates[0].updatedAt

        // 少し待ってから更新
        var updated = template
        updated.name = "更新後"
        store.update(updated)

        XCTAssertGreaterThanOrEqual(store.templates[0].updatedAt, originalDate)
    }

    func testUpdateNonExistentTemplateDoesNothing() {
        let template = CustomTemplate(name: "存在しない", promptFormat: "p")
        store.update(template)

        XCTAssertTrue(store.templates.isEmpty)
    }

    // MARK: - 削除

    func testDeleteTemplate() {
        let template = CustomTemplate(name: "削除対象", promptFormat: "p")
        store.add(template)
        XCTAssertEqual(store.templates.count, 1)

        store.delete(template)
        XCTAssertTrue(store.templates.isEmpty)
    }

    func testDeleteSpecificTemplate() {
        let t1 = CustomTemplate(name: "残す", promptFormat: "p1")
        let t2 = CustomTemplate(name: "削除", promptFormat: "p2")
        store.add(t1)
        store.add(t2)

        store.delete(t2)

        XCTAssertEqual(store.templates.count, 1)
        XCTAssertEqual(store.templates[0].name, "残す")
    }

    // MARK: - 検索

    func testTemplateForIdFound() {
        let template = CustomTemplate(name: "検索対象", promptFormat: "p")
        store.add(template)

        let found = store.template(for: template.id)
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.name, "検索対象")
    }

    func testTemplateForIdNotFound() {
        let result = store.template(for: UUID())
        XCTAssertNil(result)
    }

    // MARK: - 永続化

    func testPersistence() {
        let template = CustomTemplate(
            name: "永続化テスト",
            icon: "bolt.fill",
            templateDescription: "説明",
            promptFormat: "プロンプト"
        )
        store.add(template)

        // 新しいStoreインスタンスで読み込み
        let store2 = CustomTemplateStore(userDefaults: testDefaults)
        XCTAssertEqual(store2.templates.count, 1)
        XCTAssertEqual(store2.templates[0].name, "永続化テスト")
        XCTAssertEqual(store2.templates[0].icon, "bolt.fill")
        XCTAssertEqual(store2.templates[0].promptFormat, "プロンプト")
    }
}
