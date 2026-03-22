//
//  SearchView.swift
//  SearchGithubRepo
//

import SwiftUI

struct SearchView: View {
    @ObservedObject var container: SearchContainer
    @FocusState private var searchFocused: Bool

    private static let shortDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "MM. dd."
        return dateFormatter
    }()

    private static let countFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.locale = Locale(identifier: "ko_KR")
        return numberFormatter
    }()

    /// 네비 타이틀과 같이 `searchFocused` 기준으로 큰 타이틀(.large) 표시 여부를 맞춤.
    private var showsLargeNavigationTitle: Bool {
        !searchFocused
            && container.state.searchText.isEmpty
            && container.state.activeSearchQuery == nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBarView(
                    isSearchFieldFocused: $searchFocused,
                    searchText: Binding(
                        get: { container.state.searchText },
                        set: { container.send(.searchTextChanged($0)) }
                    ),
                    onSubmit: { container.send(.submitSearch) },
                    onClear: { container.send(.tapClearText) },
                    onCancel: { container.send(.tapCancel) }
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(searchFocused ? "" : "Search")
            .navigationBarTitleDisplayMode(
                showsLargeNavigationTitle ? .large : .inline
            )
            .onChange(of: searchFocused) { _, isSearchFieldFocused in
                container.send(.searchFieldFocused(isSearchFieldFocused))
            }
            .onChange(of: container.state.searchFieldFocused) { _, isSearchFieldFocused in
                if isSearchFieldFocused != searchFocused {
                    searchFocused = isSearchFieldFocused
                }
            }
            .onAppear {
                searchFocused = container.state.searchFieldFocused
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        let searchState = container.state

        if searchState.showsResultsSection {
            resultsContent(state: searchState)
        } else if searchState.showsAutocomplete {
            autocompleteList(state: searchState)
        } else if searchState.showsRecentSection {
            recentSection(state: searchState)
        } else {
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func resultsContent(state: SearchState) -> some View {
        Group {
            if state.isLoadingResults {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 24)
            } else if let message = state.errorMessage {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 24)
            } else {
                List {
                    Section {
                        ForEach(state.repositories) { repository in
                            RepositoryResultRow(repository: repository)
                        }
                    } header: {
                        Text(countLabel(state.totalCount))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func autocompleteList(state: SearchState) -> some View {
        List {
            ForEach(state.autocompleteCandidates) { recentSearchItem in
                Button {
                    container.send(.tapAutocompleteSuggestion(recentSearchItem))
                } label: {
                    HStack {
                        Text(recentSearchItem.query)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(Self.shortDateFormatter.string(from: recentSearchItem.searchedAt))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private func recentSection(state: SearchState) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("최근 검색")
                    .font(.headline)
                Spacer()
                if !state.recentSearches.isEmpty {
                    Button("전체삭제") {
                        container.send(.clearAllRecentSearches)
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.pink)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            if state.recentSearches.isEmpty {
                Text("최근 검색 내역이 없습니다.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                Divider()
                    .padding(.top, 8)

                Spacer(minLength: 0)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(state.recentSearches) { recentSearchItem in
                            HStack {
                                Button {
                                    container.send(.tapRecentSearch(recentSearchItem))
                                } label: {
                                    Text(recentSearchItem.query)
                                        .foregroundStyle(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    container.send(.removeRecentSearch(recentSearchItem.id))
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .padding(8)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func countLabel(_ total: Int) -> String {
        let totalCountAsNumber = NSNumber(value: total)
        let formattedCount = Self.countFormatter.string(from: totalCountAsNumber) ?? "\(total)"
        return "\(formattedCount)개 저장소"
    }
}

#Preview {
    SearchView(container: SearchContainer())
}
