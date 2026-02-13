import SwiftUI

struct SearchView: View {
    @EnvironmentObject var meetingStore: MeetingStore
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.query.isEmpty {
                    recentSearchesView
                } else if viewModel.results.isEmpty {
                    noResultsView
                } else {
                    resultsList
                }
            }
            .navigationTitle("検索")
            .searchable(text: $viewModel.query, prompt: "キーワードを入力")
            .onSubmit(of: .search) {
                viewModel.addToRecentSearches(viewModel.query)
            }
            .onAppear {
                viewModel.setStore(meetingStore)
            }
        }
    }

    private var recentSearchesView: some View {
        VStack(alignment: .leading) {
            if !viewModel.recentSearches.isEmpty {
                Text("最近の検索")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 12)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.recentSearches, id: \.self) { term in
                            Button {
                                viewModel.query = term
                            } label: {
                                Text(term)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(16)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            Spacer()
        }
    }

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("該当する議事録が見つかりません")
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private var resultsList: some View {
        List {
            Text("検索結果: \(viewModel.results.count)件")
                .font(.caption)
                .foregroundColor(.secondary)
                .listRowSeparator(.hidden)

            ForEach(viewModel.results) { meeting in
                NavigationLink {
                    MeetingDetailView(meeting: meeting)
                        .environmentObject(meetingStore)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        MeetingListItemView(meeting: meeting)
                        if let snippet = searchSnippet(for: meeting) {
                            Text(snippet)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
    }

    private func searchSnippet(for meeting: Meeting) -> String? {
        let query = viewModel.query.lowercased()
        guard !query.isEmpty else { return nil }

        // タイトルにマッチした場合はスニペット不要
        if meeting.title.lowercased().contains(query) { return nil }

        // 文字起こしテキストからマッチ箇所を抽出
        if let text = meeting.transcriptionText,
           let range = text.lowercased().range(of: query) {
            let matchIndex = text.distance(from: text.startIndex, to: range.lowerBound)
            let snippetStart = text.index(text.startIndex, offsetBy: max(0, matchIndex - 20))
            let snippetEnd = text.index(text.startIndex, offsetBy: min(text.count, matchIndex + query.count + 40))
            let snippet = String(text[snippetStart..<snippetEnd])
            let prefix = matchIndex > 20 ? "..." : ""
            let suffix = text.distance(from: text.startIndex, to: snippetEnd) < text.count ? "..." : ""
            return "\(prefix)\(snippet)\(suffix)"
        }

        // 要約テキストからマッチ箇所を抽出
        if let rawText = meeting.summary?.rawText,
           let range = rawText.lowercased().range(of: query) {
            let matchIndex = rawText.distance(from: rawText.startIndex, to: range.lowerBound)
            let snippetStart = rawText.index(rawText.startIndex, offsetBy: max(0, matchIndex - 20))
            let snippetEnd = rawText.index(rawText.startIndex, offsetBy: min(rawText.count, matchIndex + query.count + 40))
            let snippet = String(rawText[snippetStart..<snippetEnd])
            let prefix = matchIndex > 20 ? "..." : ""
            let suffix = rawText.distance(from: rawText.startIndex, to: snippetEnd) < rawText.count ? "..." : ""
            return "\(prefix)\(snippet)\(suffix)"
        }

        return nil
    }
}
