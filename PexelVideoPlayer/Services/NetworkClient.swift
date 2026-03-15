import Foundation

// MARK: - Errors

enum NetworkError: LocalizedError, Equatable {
    case invalidURL
    case rateLimited
    case serverError(Int)
    case decodingError
    case networkUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:              return PexelStringConstants.errorInvalidURL
        case .rateLimited:             return PexelStringConstants.errorRateLimited
        case .serverError(let code):   return PexelStringConstants.errorServer(code)
        case .decodingError:           return PexelStringConstants.errorDecoding
        case .networkUnavailable(let msg): return PexelStringConstants.errorNetwork(msg)
        }
    }
}

// MARK: - Protocol

protocol NetworkClientProtocol {
    func fetch<T: Decodable>(
        _ type: T.Type,
        request: URLRequest
    ) async throws -> T
}

// MARK: - Implementation

struct NetworkClient: NetworkClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder

    static let shared = NetworkClient()

    init(session: URLSession = .shared, decoder: JSONDecoder = .pexels) {
        self.session = session
        self.decoder = decoder
    }

    func fetch<T: Decodable>(
        _ type: T.Type,
        request: URLRequest
    ) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw NetworkError.networkUnavailable(error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse {
            switch http.statusCode {
            case 200...299: break
            case 429: throw NetworkError.rateLimited
            default: throw NetworkError.serverError(http.statusCode)
            }
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }
}

// MARK: - JSONDecoder convenience

extension JSONDecoder {
    static var pexels: JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }
}
