import Foundation

// MARK: - Protocol

protocol PexelsAPIServiceProtocol {
    func fetchPopularVideos(page: Int, perPage: Int) async throws -> PexelsResponse
//    func searchVideos(query: String, page: Int, perPage: Int) async throws -> PexelsResponse
}

// MARK: - Implementation

struct PexelsAPIService: PexelsAPIServiceProtocol {
    static let shared = PexelsAPIService()

    private let client: NetworkClientProtocol
    private let apiKey: String
    private let popularURL = "https://api.pexels.com/videos/popular"
    private let searchURL  = "https://api.pexels.com/videos/search"

    private init(
        client: NetworkClientProtocol = NetworkClient.shared,
        apiKey: String = "M80Auk9SXktZ1Hyw0X4cbnfbV5WddejHFZ9c1YrLMPDJtLitu7VKIDTs"
    ) {
        self.client = client
        self.apiKey = apiKey
    }

    func fetchPopularVideos(page: Int, perPage: Int = 15) async throws -> PexelsResponse {
        let url = try buildURL(popularURL, queryItems: [
            URLQueryItem(name: "page",     value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)")
        ])
        return try await client.fetch(request: authorised(url))
    }

    func searchVideos(query: String, page: Int, perPage: Int = 15) async throws -> PexelsResponse {
        let url = try buildURL(searchURL, queryItems: [
            URLQueryItem(name: "query",    value: query),
            URLQueryItem(name: "page",     value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)")
        ])
        return try await client.fetch(request: authorised(url))
    }

    // MARK: - Helpers

    private func buildURL(_ base: String, queryItems: [URLQueryItem]) throws -> URL {
        guard var components = URLComponents(string: base) else { throw NetworkError.invalidURL }
        components.queryItems = queryItems
        guard let url = components.url else { throw NetworkError.invalidURL }
        return url
    }

    private func authorised(_ url: URL) -> URLRequest {
        var req = URLRequest(url: url)
        req.setValue(apiKey, forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 15
        return req
    }
}
