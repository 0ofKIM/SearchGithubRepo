//
//  Repository.swift
//  SearchGithubRepo
//

import Foundation

struct Repository: Identifiable, Equatable, Codable {
    let id: Int64
    let name: String
    let htmlURL: String
    let owner: Owner

    struct Owner: Equatable, Codable {
        let login: String
        let avatarURL: String

        enum CodingKeys: String, CodingKey {
            case login
            case avatarURL = "avatar_url"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case htmlURL = "html_url"
        case owner
    }
}

struct SearchRepositoriesResponse: Decodable {
    let totalCount: Int
    let items: [Repository]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case items
    }
}
