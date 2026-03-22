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
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return recentSearches.filter {
            $0.query.localizedStandardContains(trimmed)
        }
    }

    var showsLargeNavigationTitle: Bool {
        !searchFieldFocused && searchText.isEmpty && activeSearchQuery == nil
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
        case .searchTextChanged(let text):
            state.searchText = text
            if let active = state.activeSearchQuery, text != active {
                state.activeSearchQuery = nil
                state.repositories = []
                state.totalCount = 0
                state.errorMessage = nil
            }

        case .searchFieldFocused(let focused):
            if state.searchFieldFocused != focused {
                state.searchFieldFocused = focused
            }

        case .submitSearch:
            let trimmed = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            searchTask?.cancel()
            state.activeSearchQuery = trimmed
            state.searchFieldFocused = false
            state.errorMessage = nil
            recentSearchStorage.add(query: trimmed)
            state.recentSearches = recentSearchStorage.load()
            searchTask = Task { [weak self] in
                await self?.performSearch(query: trimmed)
            }

        case .tapCancel:
            state.searchFieldFocused = false

        case .tapClearText:
            state.searchText = ""
            state.activeSearchQuery = nil
            state.repositories = []
            state.totalCount = 0
            state.errorMessage = nil

        case .tapRecentSearch(let item):
            state.searchText = item.query
            state.activeSearchQuery = nil
            state.repositories = []
            state.totalCount = 0
            state.errorMessage = nil
            state.searchFieldFocused = true

        case .tapAutocompleteSuggestion(let item):
            state.searchText = item.query
            state.activeSearchQuery = nil
            state.repositories = []
            state.totalCount = 0
            state.errorMessage = nil
            state.searchFieldFocused = true

        case .removeRecentSearch(let id):
            recentSearchStorage.remove(id: id)
            state.recentSearches = recentSearchStorage.load()

        case .clearAllRecentSearches:
            recentSearchStorage.removeAll()
            state.recentSearches = []
        }
    }

    private func performSearch(query: String) async {
        state.isLoadingResults = true
        defer { state.isLoadingResults = false }

        do {
            let response = try await gitHubSearchService.searchRepositories(query: query, page: 1)
            guard !Task.isCancelled else { return }
            guard state.activeSearchQuery == query else { return }
            state.repositories = response.items
            state.totalCount = response.totalCount
            state.errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            guard state.activeSearchQuery == query else { return }
            state.repositories = []
            state.totalCount = 0
            state.errorMessage = error.localizedDescription
        }
    }
}
