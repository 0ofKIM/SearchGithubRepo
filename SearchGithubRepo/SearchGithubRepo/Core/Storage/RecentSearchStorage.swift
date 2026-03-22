//
//  RecentSearchStorage.swift
//  SearchGithubRepo
//

import Foundation

struct RecentSearchStorage: Sendable {
    private let userDefaults: UserDefaults
    private let userDefaultsKey = "recentSearchItems"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> [RecentSearchItem] {
        guard let storedData = userDefaults.data(forKey: userDefaultsKey) else { return [] }
        do {
            let decodedItems = try JSONDecoder().decode([RecentSearchItem].self, from: storedData)
            return decodedItems.sorted { $0.searchedAt > $1.searchedAt }
        } catch {
            return []
        }
    }

    func save(_ items: [RecentSearchItem]) {
        let sortedItems = items.sorted { $0.searchedAt > $1.searchedAt }
        let limitedItems = Array(sortedItems.prefix(10))
        guard let encodedData = try? JSONEncoder().encode(limitedItems) else { return }
        userDefaults.set(encodedData, forKey: userDefaultsKey)
    }

    func add(query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }
        var loadedItems = load()
        loadedItems.removeAll { $0.query.caseInsensitiveCompare(trimmedQuery) == .orderedSame }
        loadedItems.append(RecentSearchItem(query: trimmedQuery, searchedAt: .now))
        save(loadedItems)
    }

    func remove(recentSearchItemID: UUID) {
        var loadedItems = load()
        loadedItems.removeAll { $0.id == recentSearchItemID }
        save(loadedItems)
    }

    func removeAll() {
        userDefaults.removeObject(forKey: userDefaultsKey)
    }
}
