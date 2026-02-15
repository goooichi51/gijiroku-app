import XCTest
@testable import GijirokuApp

@MainActor
final class SearchViewModelTests: XCTestCase {

    private var viewModel: SearchViewModel!
    private let testKey = "recent_searches"
    private var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: testKey)
        testDefaults = UserDefaults(suiteName: "SearchViewModelTests")!
        testDefaults.removePersistentDomain(forName: "SearchViewModelTests")
        viewModel = SearchViewModel()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: testKey)
        testDefaults.removePersistentDomain(forName: "SearchViewModelTests")
        viewModel = nil
        super.tearDown()
    }

    private func makeIsolatedStore() -> MeetingStore {
        MeetingStore(userDefaults: testDefaults)
    }

    // MARK: - Recent Searches

    func testAddToRecentSearches() {
        viewModel.addToRecentSearches("テスト")
        XCTAssertEqual(viewModel.recentSearches, ["テスト"])
    }

    func testAddToRecentSearchesTrimmed() {
        viewModel.addToRecentSearches("  空白  ")
        XCTAssertEqual(viewModel.recentSearches.first, "空白")
    }

    func testAddToRecentSearchesIgnoresEmpty() {
        viewModel.addToRecentSearches("")
        XCTAssertTrue(viewModel.recentSearches.isEmpty)
    }

    func testAddToRecentSearchesIgnoresWhitespace() {
        viewModel.addToRecentSearches("   ")
        XCTAssertTrue(viewModel.recentSearches.isEmpty)
    }

    func testRecentSearchesMaxFive() {
        for i in 1...7 {
            viewModel.addToRecentSearches("検索\(i)")
        }
        XCTAssertEqual(viewModel.recentSearches.count, 5)
        XCTAssertEqual(viewModel.recentSearches.first, "検索7")
    }

    func testRecentSearchesNoDuplicates() {
        viewModel.addToRecentSearches("議事録")
        viewModel.addToRecentSearches("会議")
        viewModel.addToRecentSearches("議事録")
        XCTAssertEqual(viewModel.recentSearches, ["議事録", "会議"])
    }

    func testClearRecentSearches() {
        viewModel.addToRecentSearches("テスト1")
        viewModel.addToRecentSearches("テスト2")
        viewModel.clearRecentSearches()
        XCTAssertTrue(viewModel.recentSearches.isEmpty)
    }

    func testRecentSearchesPersistence() {
        viewModel.addToRecentSearches("永続化テスト")
        let saved = UserDefaults.standard.stringArray(forKey: testKey)
        XCTAssertEqual(saved, ["永続化テスト"])
    }

    // MARK: - Search

    func testPerformSearchWithoutStoreReturnsEmpty() {
        viewModel.performSearch(query: "何か")
        XCTAssertTrue(viewModel.results.isEmpty)
    }

    func testPerformSearchWithStore() {
        let store = makeIsolatedStore()
        let meeting = Meeting(title: "ユニークテスト定例XYZ", template: .standard)
        store.add(meeting)
        viewModel.setStore(store)

        viewModel.performSearch(query: "ユニークテスト定例XYZ")
        XCTAssertEqual(viewModel.results.count, 1)
        XCTAssertEqual(viewModel.results.first?.title, "ユニークテスト定例XYZ")
    }

    func testPerformSearchNoMatch() {
        let store = makeIsolatedStore()
        let meeting = Meeting(title: "テスト会議ABC", template: .standard)
        store.add(meeting)
        viewModel.setStore(store)

        viewModel.performSearch(query: "マッチしない文字列ZZZ")
        XCTAssertTrue(viewModel.results.isEmpty)
    }

    func testSearchResultsSortedByTitleMatchFirst() {
        let store = makeIsolatedStore()
        var meetingA = Meeting(title: "プロジェクトXYZ報告", template: .standard)
        meetingA.transcriptionText = "今日のミーティングXYZについて"
        store.add(meetingA)

        let meetingB = Meeting(title: "ミーティングXYZの記録", template: .standard)
        store.add(meetingB)

        viewModel.setStore(store)
        viewModel.performSearch(query: "ミーティングXYZ")

        XCTAssertEqual(viewModel.results.count, 2)
        XCTAssertEqual(viewModel.results.first?.title, "ミーティングXYZの記録")
    }

    func testInitialState() {
        XCTAssertEqual(viewModel.query, "")
        XCTAssertTrue(viewModel.results.isEmpty)
    }
}
