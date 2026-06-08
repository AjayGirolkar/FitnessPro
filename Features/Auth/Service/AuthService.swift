//
//  AuthService.swift
//  FitnessPro
//
//  Auth abstraction. MockAuthService fakes sign-in locally with zero
//  dependencies. Swap in a FirebaseAuthService (Google/Apple/email) later
//  behind this same protocol — call sites won't change.
//

import Foundation

enum AuthError: LocalizedError, Equatable {
    case invalidEmail
    case weakPassword
    case emptyFields
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidEmail: return "Enter a valid email address."
        case .weakPassword: return "Password must be at least 6 characters."
        case .emptyFields:  return "Please fill in all fields."
        case .unknown:      return "Something went wrong. Try again."
        }
    }
}

protocol AuthService: Sendable {
    func currentUser() -> User?
    func signIn(email: String, password: String) async throws -> User
    func signUp(name: String, email: String, password: String) async throws -> User
    func signInWithGoogle() async throws -> User
    func signInWithApple() async throws -> User
    /// One-tap demo login. Skips the form and validation so the full app
    /// flow can be exercised without typing real credentials.
    func signInAsDemo() async throws -> User
    func signOut()
}

extension AuthService {
    var demoUser: User {
        User(name: "Demo Athlete", email: "demo@fitnesspro.app", provider: .email)
    }
}

/// Local mock. Persists the "session" in the key-value store and applies
/// light validation so the UI flows feel real without a backend.
struct MockAuthService: AuthService {
    private let store: KeyValueStore
    private let sessionKey = "auth.currentUser"

    init(store: KeyValueStore) {
        self.store = store
    }

    func currentUser() -> User? {
        store.value(forKey: sessionKey, as: User.self)
    }

    func signIn(email: String, password: String) async throws -> User {
        try validate(email: email, password: password)
        try await fakeLatency()
        let user = User(name: derivedName(from: email), email: email, provider: .email)
        persist(user)
        return user
    }

    func signUp(name: String, email: String, password: String) async throws -> User {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { throw AuthError.emptyFields }
        try validate(email: email, password: password)
        try await fakeLatency()
        let user = User(name: name, email: email, provider: .email)
        persist(user)
        return user
    }

    func signInWithGoogle() async throws -> User {
        try await fakeLatency()
        let user = User(name: "Google User", email: "user@gmail.com", provider: .google)
        persist(user)
        return user
    }

    func signInWithApple() async throws -> User {
        try await fakeLatency()
        let user = User(name: "Apple User", email: "user@icloud.com", provider: .apple)
        persist(user)
        return user
    }

    func signInAsDemo() async throws -> User {
        try await fakeLatency()
        persist(demoUser)
        return demoUser
    }

    func signOut() {
        store.remove(forKey: sessionKey)
    }

    // MARK: Helpers
    private func persist(_ user: User) { store.set(user, forKey: sessionKey) }

    private func fakeLatency() async throws {
        try await Task.sleep(for: .milliseconds(600))
    }

    private func validate(email: String, password: String) throws {
        guard !email.isEmpty, !password.isEmpty else { throw AuthError.emptyFields }
        guard email.contains("@"), email.contains(".") else { throw AuthError.invalidEmail }
        guard password.count >= 6 else { throw AuthError.weakPassword }
    }

    private func derivedName(from email: String) -> String {
        let handle = email.split(separator: "@").first.map(String.init) ?? "Athlete"
        return handle.replacingOccurrences(of: ".", with: " ").capitalized
    }
}
