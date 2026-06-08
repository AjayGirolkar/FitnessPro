//
//  AuthViewModel.swift
//  FitnessPro
//
//  Drives Login + Sign Up. Holds form fields and a single view state.
//  On success it hands the User back via `onAuthenticated` so the root
//  coordinator can advance the app flow.
//

import Foundation
import Observation

@MainActor
@Observable
final class AuthViewModel {
    enum State: Equatable {
        case idle
        case loading
        case error(String)
    }

    // Form fields
    var name = ""
    var email = ""
    var password = ""

    private(set) var state: State = .idle

    private let service: AuthService
    /// Set by the root coordinator to advance the flow after auth.
    var onAuthenticated: (User) -> Void = { _ in }
    /// Demo-login success. Defaults to the normal path; the coordinator
    /// overrides it to force the full onboarding flow.
    var onDemoAuthenticated: ((User) -> Void)?

    init(service: AuthService) {
        self.service = service
    }

    var isWorking: Bool { state == .loading }

    var errorMessage: String? {
        if case let .error(message) = state { return message }
        return nil
    }

    func signIn() async {
        await run { try await self.service.signIn(email: self.email, password: self.password) }
    }

    func signUp() async {
        await run { try await self.service.signUp(name: self.name, email: self.email, password: self.password) }
    }

    func continueWithGoogle() async {
        await run { try await self.service.signInWithGoogle() }
    }

    func continueWithApple() async {
        await run { try await self.service.signInWithApple() }
    }

    /// One-tap mock login — bypasses the form and lands in onboarding.
    func signInAsDemo() async {
        await run({ try await self.service.signInAsDemo() }, onSuccess: onDemoAuthenticated)
    }

    /// Drops demo credentials into the form so the user can review the
    /// prefilled fields and tap Log In, instead of authenticating instantly.
    func fillDemoCredentials() {
        name = "Demo Athlete"
        email = "demo@fitnesspro.app"
        password = "demo123"
    }

    // MARK: - Shared runner
    private func run(
        _ operation: @escaping () async throws -> User,
        onSuccess: ((User) -> Void)? = nil
    ) async {
        state = .loading
        do {
            let user = try await operation()
            state = .idle
            (onSuccess ?? onAuthenticated)(user)
        } catch let error as AuthError {
            state = .error(error.localizedDescription)
        } catch {
            state = .error(AuthError.unknown.localizedDescription)
        }
    }
}
