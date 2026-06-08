//
//  NetworkError.swift
//  FitnessPro
//

import Foundation

enum NetworkError: Error, Equatable {
    case invalidURL
    case requestFailed(statusCode: Int)
    case decodingFailed
    case noConnection
    case unknown

    var userMessage: String {
        switch self {
        case .invalidURL:        return "Something went wrong. Please try again."
        case .requestFailed:     return "The server returned an error. Please try again."
        case .decodingFailed:    return "We couldn't read the response."
        case .noConnection:      return "No internet connection."
        case .unknown:           return "An unexpected error occurred."
        }
    }
}
