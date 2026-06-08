//
//  Endpoint.swift
//  FitnessPro
//
//  Declarative request description. Build URLRequests from these so call
//  sites stay free of URL/string assembly.
//

import Foundation

struct Endpoint {
    var path: String
    var method: HTTPMethod = .get
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: Data?

    // TODO: Move base URL into a build configuration (xcconfig) per environment.
    static let baseURL = URL(string: "https://api.fitnesspro.example.com")!

    func makeRequest() throws -> URLRequest {
        guard var components = URLComponents(
            url: Self.baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else {
            throw NetworkError.invalidURL
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        return request
    }
}
