//
//  WebPresentation.swift
//  SearchGithubRepo
//

import Foundation

struct WebPresentation: Identifiable, Equatable {
    let id: String
    let url: URL

    init?(repository: RepositoryDTO) {
        guard let url = URL(string: repository.htmlURL) else { return nil }
        self.url = url
        id = repository.htmlURL
    }
}
