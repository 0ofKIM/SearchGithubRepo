//
//  RecentSearchItem.swift
//  SearchGithubRepo
//

import Foundation

struct RecentSearchItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let query: String
    let searchedAt: Date

    init(id: UUID = UUID(), query: String, searchedAt: Date = .now) {
        self.id = id
        self.query = query
        self.searchedAt = searchedAt
    }
}
