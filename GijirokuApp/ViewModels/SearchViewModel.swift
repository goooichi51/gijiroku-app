import Foundation
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [Meeting] = []
    @Published var recentSearches: [String] = []

    private var meetingStore: MeetingStore?
    private var cancellables = Set<AnyCancellable>()
    private let recentSearchesKey = "recent_searches"

    init() {
        loadRecentSearches()
        // デバウンスで検索
        $query
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }

    func setStore(_ store: MeetingStore) {
        self.meetingStore = store
    }

    func performSearch(query: String) {
        guard let store = meetingStore else { return }
        let searchResults = store.search(query: query)
        // タイトルマッチを優先、同順位は新しい日付順
        let lowercased = query.lowercased()
        results = searchResults.sorted { lhs, rhs in
            let lhsTitleMatch = lhs.title.lowercased().contains(lowercased)
            let rhsTitleMatch = rhs.title.lowercased().contains(lowercased)
            if lhsTitleMatch != rhsTitleMatch {
                return lhsTitleMatch
            }
            return lhs.date > rhs.date
        }
    }

    func addToRecentSearches(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        recentSearches.removeAll { $0 == trimmed }
        recentSearches.insert(trimmed, at: 0)
        if recentSearches.count > 5 {
            recentSearches = Array(recentSearches.prefix(5))
        }
        saveRecentSearches()
    }

    func clearRecentSearches() {
        recentSearches.removeAll()
        saveRecentSearches()
    }

    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: recentSearchesKey) ?? []
    }

    private func saveRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: recentSearchesKey)
    }
}
