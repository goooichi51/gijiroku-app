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
                    MeetingListItemView(meeting: meeting)
                }
            }
        }
    }
}
