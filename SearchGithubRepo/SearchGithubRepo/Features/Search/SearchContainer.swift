//
//  SearchContainer.swift
//  SearchGithubRepo
//

import Combine
import Foundation

// MARK: - State

struct SearchState: Equatable {
    var searchText: String
    var searchFieldFocused: Bool
    /// 검색 실행 후 결과 영역에 표시 중인 쿼리. `nil`이면 최근 검색/자동완성 영역.
    var activeSearchQuery: String?
    var recentSearches: [RecentSearchItem]
    var repositories: [Repository]
    var totalCount: Int
    var isLoadingResults: Bool
    var errorMessage: String?

    static let initial = SearchState(
        searchText: "",
        searchFieldFocused: false,
        activeSearchQuery: nil,
        recentSearches: [],
        repositories: [],
        totalCount: 0,
        isLoadingResults: false,
        errorMessage: nil
    )

    var autocompleteCandidates: [RecentSearchItem] {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearchText.isEmpty else { return [] }
        return recentSearches.filter {
            $0.query.localizedStandardContains(trimmedSearchText)
        }
    }

    var showsRecentSection: Bool {
        activeSearchQuery == nil && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var showsAutocomplete: Bool {
        activeSearchQuery == nil
            && searchFieldFocused
            && !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !autocompleteCandidates.isEmpty
    }

    var showsResultsSection: Bool {
        activeSearchQuery != nil
    }
}

// MARK: - Intent

enum SearchIntent: Equatable {
    case searchTextChanged(String)
    case searchFieldFocused(Bool)
    case submitSearch
    case tapCancel
    case tapClearText
    case tapRecentSearch(RecentSearchItem)
    case tapAutocompleteSuggestion(RecentSearchItem)
    case removeRecentSearch(UUID)
    case clearAllRecentSearches
}

// MARK: - Container

@MainActor
final class SearchContainer: ObservableObject {
    @Published private(set) var state: SearchState

    private let recentSearchStorage: RecentSearchStorage
    private let gitHubSearchService: GitHubSearchService
    private var searchTask: Task<Void, Never>?

    init(
        recentSearchStorage: RecentSearchStorage = RecentSearchStorage(),
        gitHubSearchService: GitHubSearchService = GitHubSearchService()
    ) {
        self.recentSearchStorage = recentSearchStorage
        self.gitHubSearchService = gitHubSearchService
        var initial = SearchState.initial
        initial.recentSearches = recentSearchStorage.load()
        state = initial
    }

    func send(_ intent: SearchIntent) {
        switch intent {
        case .searchTextChanged(let newSearchText):
            state.searchText = newSearchText
            if let activeSearchQuery = state.activeSearchQuery, newSearchText != activeSearchQuery {
                state.activeSearchQuery = nil
                state.repositories = []
                state.totalCount = 0
                state.errorMessage = nil
            }

        case .searchFieldFocused(let isSearchFieldFocused):
            if state.searchFieldFocused != isSearchFieldFocused {
                state.searchFieldFocused = isSearchFieldFocused
            }

        case .submitSearch:
            let trimmedSearchText = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedSearchText.isEmpty else { return }
            searchTask?.cancel()
            state.activeSearchQuery = trimmedSearchText
            state.searchFieldFocused = false
            state.errorMessage = nil
            recentSearchStorage.add(query: trimmedSearchText)
            state.recentSearches = recentSearchStorage.load()
            searchTask = Task { [weak self] in
                await self?.performSearch(query: trimmedSearchText)
            }

        case .tapCancel:
            state.searchFieldFocused = false

        case .tapClearText:
            state.searchText = ""
            state.activeSearchQuery = nil
            state.repositories = []
            state.totalCount = 0
            state.errorMessage = nil

        case .tapRecentSearch(let recentSearchItem):
            state.searchText = recentSearchItem.query
            state.activeSearchQuery = nil
            state.repositories = []
            state.totalCount = 0
            state.errorMessage = nil
            state.searchFieldFocused = true

        case .tapAutocompleteSuggestion(let recentSearchItem):
            state.searchText = recentSearchItem.query
            state.activeSearchQuery = nil
            state.repositories = []
            state.totalCount = 0
            state.errorMessage = nil
            state.searchFieldFocused = true

        case .removeRecentSearch(let recentSearchItemID):
            recentSearchStorage.remove(recentSearchItemID: recentSearchItemID)
            state.recentSearches = recentSearchStorage.load()

        case .clearAllRecentSearches:
            recentSearchStorage.removeAll()
            state.recentSearches = []
        }
    }

    private func performSearch(query searchQuery: String) async {
        state.isLoadingResults = true
        defer { state.isLoadingResults = false }

        do {
            let searchResponse = try await gitHubSearchService.searchRepositories(query: searchQuery, page: 1)
            guard !Task.isCancelled else { return }
            guard state.activeSearchQuery == searchQuery else { return }
            state.repositories = searchResponse.items
            state.totalCount = searchResponse.totalCount
            state.errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            guard state.activeSearchQuery == searchQuery else { return }
            state.repositories = []
            state.totalCount = 0
            state.errorMessage = error.localizedDescription
        }
    }
}
