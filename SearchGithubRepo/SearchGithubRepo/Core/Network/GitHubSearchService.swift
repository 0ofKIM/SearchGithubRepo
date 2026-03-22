//
//  GitHubSearchService.swift
//  SearchGithubRepo
//

import Foundation

enum GitHubSearchError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "요청 주소가 올바르지 않습니다."
        case .invalidResponse:
            return "서버 응답을 해석할 수 없습니다."
        case .httpStatus(let code):
            return "GitHub API 오류 (코드 \(code))"
        case .decoding:
            return "응답 데이터를 읽을 수 없습니다."
        }
    }
}

actor GitHubSearchService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func searchRepositories(query: String, page: Int) async throws -> SearchRepositoriesResponse {
        var components = URLComponents(string: "https://api.github.com/search/repositories")
        guard var components else { throw GitHubSearchError.invalidURL }
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page", value: "\(page)")
        ]
        guard let url = components.url else { throw GitHubSearchError.invalidURL }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GitHubSearchError.invalidResponse }
        guard (200 ... 299).contains(http.statusCode) else { throw GitHubSearchError.httpStatus(http.statusCode) }

        do {
            return try JSONDecoder().decode(SearchRepositoriesResponse.self, from: data)
        } catch {
            throw GitHubSearchError.decoding(error)
        }
    }
}
