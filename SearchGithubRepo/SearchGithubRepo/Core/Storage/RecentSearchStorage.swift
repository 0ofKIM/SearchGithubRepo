//
//  RecentSearchStorage.swift
//  SearchGithubRepo
//

import Foundation

struct RecentSearchStorage: Sendable {
    private let userDefaults: UserDefaults
    private let key = "recentSearchItems"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> [RecentSearchItem] {
        guard let data = userDefaults.data(forKey: key) else { return [] }
        do {
            let decoded = try JSONDecoder().decode([RecentSearchItem].self, from: data)
            return decoded.sorted { $0.searchedAt > $1.searchedAt }
        } catch {
            return []
        }
    }

    func save(_ items: [RecentSearchItem]) {
        let sorted = items.sorted { $0.searchedAt > $1.searchedAt }
        let limited = Array(sorted.prefix(10))
        guard let data = try? JSONEncoder().encode(limited) else { return }
        userDefaults.set(data, forKey: key)
    }

    func add(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var items = load()
        items.removeAll { $0.query.caseInsensitiveCompare(trimmed) == .orderedSame }
        items.append(RecentSearchItem(query: trimmed, searchedAt: .now))
        save(items)
    }

    func remove(id: UUID) {
        var items = load()
        items.removeAll { $0.id == id }
        save(items)
    }

    func removeAll() {
        userDefaults.removeObject(forKey: key)
    }
}
