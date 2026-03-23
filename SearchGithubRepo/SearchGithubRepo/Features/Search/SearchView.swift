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
            .sheet(item: webSheetBinding) { presentation in
                NavigationStack {
                    RepositoryWebView(url: presentation.url)
                        .navigationTitle("저장소")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("닫기") {
                                    container.send(.dismissWebSheet)
                                }
                            }
                        }
                }
            }
        }
    }

    private var webSheetBinding: Binding<WebPresentation?> {
        Binding(
            get: { container.state.presentedRepositoryWeb },
            set: { newValue in
                if newValue == nil {
                    container.send(.dismissWebSheet)
                }
            }
        )
    }

    @ViewBuilder
    private var content: some View {
        let searchState = container.state

        if searchState.showsResultsSection {
            ResultsListView(
                state: searchState,
                onTapRepository: { container.send(.tapRepository($0)) },
                onPrefetchNextPage: { container.send(.prefetchNextPage) },
                countLabelText: countLabel(searchState.totalCount)
            )
        } else if searchState.showsAutocomplete {
            AutoCompleteListView(
                items: searchState.autocompleteCandidates,
                formatDateText: { Self.shortDateFormatter.string(from: $0) },
                onSelectRecentSearch: { container.send(.selectRecentSearch($0)) }
            )
        } else if searchState.showsRecentSection {
            RecentSearchSectionView(
                recentSearches: searchState.recentSearches,
                recentSearchesDisplayed: searchState.recentSearchesDisplayed,
                onSelectRecentSearch: { container.send(.selectRecentSearch($0)) },
                onRemoveRecentSearch: { container.send(.removeRecentSearch($0)) },
                onClearAllRecentSearches: { container.send(.clearAllRecentSearches) }
            )
        } else {
            Spacer(minLength: 0)
        }
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
