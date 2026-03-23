//
//  SearchContainer.swift
//  SearchGithubRepo
//

import Combine
import Foundation

// MARK: - Web sheet

struct WebPresentation: Identifiable, Equatable {
    let id: String
    let url: URL

    init?(repository: RepositoryDTO) {
        guard let url = URL(string: repository.htmlURL) else { return nil }
        self.url = url
        id = repository.htmlURL
    }
}

// MARK: - State

struct SearchState: Equatable {
    var searchText: String
    var searchFieldFocused: Bool
    /// 검색 실행 후 결과 영역에 표시 중인 쿼리. `nil`이면 최근 검색/자동완성 영역.
    var activeSearchQuery: String?
    /// 저장소에 보관된 전체 최근 검색(날짜 내림차순). UI 목록은 `recentSearchesDisplayed`만 사용.
    var recentSearches: [RecentSearchItem]
    var repositories: [RepositoryDTO]
    var totalCount: Int
    var isLoadingResults: Bool
    var isPaginating: Bool
    var hasMorePages: Bool
    var errorMessage: String?
    var presentedRepositoryWeb: WebPresentation?

    static let initial = SearchState(
        searchText: "",
        searchFieldFocused: false,
        activeSearchQuery: nil,
        recentSearches: [],
        repositories: [],
        totalCount: 0,
        isLoadingResults: false,
        isPaginating: false,
        hasMorePages: false,
        errorMessage: nil,
        presentedRepositoryWeb: nil
    )

    /// 최근 검색 목록에 노출할 항목(최대 10개). 삭제 시 그 다음 우선순위 항목이 채워짐.
    var recentSearchesDisplayed: [RecentSearchItem] {
        Array(recentSearches.prefix(10))
    }

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
    case selectRecentSearch(RecentSearchItem)
    case removeRecentSearch(UUID)
    case clearAllRecentSearches
    case tapRepository(RepositoryDTO)
    case dismissWebSheet
    case prefetchNextPage
}

// MARK: - Container

@MainActor
final class SearchContainer: ObservableObject {
    @Published private(set) var state: SearchState

    private let recentSearchStorage: RecentSearchStorage
    private let gitHubSearchService: GitHubSearchService
    private var searchTask: Task<Void, Never>?
    private var paginationTask: Task<Void, Never>?
    /// 다음에 요청할 GitHub `page` (1-based). 1페이지는 `performSearch`에서만 호출.
    private var nextPageToLoad: Int = 2

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
                state.hasMorePages = false
                state.presentedRepositoryWeb = nil
                paginationTask?.cancel()
            }

        case .searchFieldFocused(let isSearchFieldFocused):
            if state.searchFieldFocused != isSearchFieldFocused {
                state.searchFieldFocused = isSearchFieldFocused
            }

        case .submitSearch:
            let trimmedSearchText = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            startSearch(with: trimmedSearchText)

        case .tapCancel:
            state.searchFieldFocused = false

        case .tapClearText:
            state.searchText = ""
            state.activeSearchQuery = nil
            state.repositories = []
            state.totalCount = 0
            state.errorMessage = nil
            state.hasMorePages = false
            state.presentedRepositoryWeb = nil
            paginationTask?.cancel()

        case .selectRecentSearch(let recentSearchItem):
            let trimmedSearchText = recentSearchItem.query.trimmingCharacters(in: .whitespacesAndNewlines)
            state.searchText = trimmedSearchText
            startSearch(with: trimmedSearchText)

        case .removeRecentSearch(let recentSearchItemID):
            recentSearchStorage.remove(recentSearchItemID: recentSearchItemID)
            state.recentSearches = recentSearchStorage.load()

        case .clearAllRecentSearches:
            recentSearchStorage.removeAll()
            state.recentSearches = []

        case .tapRepository(let repository):
            if let presentation = WebPresentation(repository: repository) {
                state.presentedRepositoryWeb = presentation
            }

        case .dismissWebSheet:
            state.presentedRepositoryWeb = nil

        case .prefetchNextPage:
            guard state.activeSearchQuery != nil else { return }
            guard state.hasMorePages, !state.isLoadingResults else { return }
            guard !state.isPaginating else { return }
            state.isPaginating = true
            paginationTask?.cancel()
            paginationTask = Task { [weak self] in
                defer { self?.state.isPaginating = false }
                await self?.loadNextPage()
            }
        }
    }
    
    private func startSearch(with trimmedQuery: String) {
        guard !trimmedQuery.isEmpty else { return }
        searchTask?.cancel()
        paginationTask?.cancel()
        state.activeSearchQuery = trimmedQuery
        state.searchFieldFocused = false
        state.errorMessage = nil
        state.presentedRepositoryWeb = nil
        state.hasMorePages = false
        nextPageToLoad = 2
        recentSearchStorage.add(query: trimmedQuery)
        state.recentSearches = recentSearchStorage.load()
        searchTask = Task { [weak self] in
            await self?.performSearch(query: trimmedQuery)
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
            state.hasMorePages = !searchResponse.items.isEmpty
                && state.repositories.count < state.totalCount
            nextPageToLoad = 2
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            guard state.activeSearchQuery == searchQuery else { return }
            state.repositories = []
            state.totalCount = 0
            state.hasMorePages = false
            state.errorMessage = error.localizedDescription
        }
    }

    private func loadNextPage() async {
        guard let activeSearchQuery = state.activeSearchQuery else { return }
        let page = nextPageToLoad

        do {
            let searchResponse = try await gitHubSearchService.searchRepositories(
                query: activeSearchQuery,
                page: page
            )
            guard !Task.isCancelled else { return }
            guard state.activeSearchQuery == activeSearchQuery else { return }
            state.repositories.append(contentsOf: searchResponse.items)
            state.hasMorePages = !searchResponse.items.isEmpty
                && state.repositories.count < state.totalCount
            nextPageToLoad = page + 1
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            guard state.activeSearchQuery == activeSearchQuery else { return }
            state.hasMorePages = false
        }
    }
}
