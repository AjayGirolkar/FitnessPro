//
//  APIClient.swift
//  FitnessPro
//
//  Thin async/await wrapper over URLSession. Protocol-first so features
//  depend on the abstraction and tests inject a mock.
//

import Foundation

protocol APIClient: Sendable {
    func send<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T
}

struct URLSessionAPIClient: APIClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = .init()) {
        self.session = session
        self.decoder = decoder
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func send<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        let request = try endpoint.makeRequest()

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw NetworkError.noConnection
        } catch {
            throw NetworkError.unknown
        }

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }
        guard (200..<300).contains(http.statusCode) else {
            throw NetworkError.requestFailed(statusCode: http.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed
        }
    }
}
