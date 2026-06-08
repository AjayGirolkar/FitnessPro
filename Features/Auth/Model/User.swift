//
//  User.swift
//  FitnessPro
//

import Foundation

/// Authenticated user. `provider` records how they signed in so the UI can
/// show the right badge and a real backend can be swapped in later.
struct User: Identifiable, Codable, Equatable, Sendable {
    let id: String
    var name: String
    var email: String
    var provider: AuthProvider
    var avatarSystemImage: String

    init(
        id: String = UUID().uuidString,
        name: String,
        email: String,
        provider: AuthProvider,
        avatarSystemImage: String = "person.crop.circle.fill"
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.provider = provider
        self.avatarSystemImage = avatarSystemImage
    }
}

enum AuthProvider: String, Codable, Sendable {
    case email
    case google
    case apple

    var displayName: String {
        switch self {
        case .email:  return "Email"
        case .google: return "Google"
        case .apple:  return "Apple"
        }
    }
}

extension User {
    static let preview = User(name: "Ajay Girolkar", email: "ajay@fitnesspro.app", provider: .email)
}
