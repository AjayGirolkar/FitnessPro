//
//  FitnessProApp.swift
//  FitnessPro
//
//  App entry point. Wires the DI container into the SwiftUI environment and
//  renders the flow chosen by AppState via the RootCoordinator.
//

import SwiftUI

@main
struct FitnessProApp: App {
    @State private var container: AppContainer = {
        // UI tests launch with a clean slate.
        if ProcessInfo.processInfo.arguments.contains("UITEST-RESET") {
            let defaults = UserDefaults.standard
            ["auth.currentUser", "app.profile", "app.activePlan"].forEach { defaults.removeObject(forKey: $0) }
        }
        return AppContainer()
    }()

    var body: some Scene {
        WindowGroup {
            RootCoordinator()
                .environment(container)
                .preferredColorScheme(.dark)
                .tint(Theme.Colors.accent)
        }
    }
}

/// Top-level router. Renders the screen for the current AppState.route.
struct RootCoordinator: View {
    @Environment(AppContainer.self) private var container

    var body: some View {
        let state = container.appState
        Group {
            switch state.route {
            case .landing:
                LandingView(onGetStarted: state.getStarted, onLogIn: state.getStarted)
            case .auth:
                AuthScreen(container: container)
            case .onboarding:
                NavigationStack { OnboardingScreen(container: container) }
            case .planResult:
                NavigationStack { PlanResultScreen(container: container) }
            case .main:
                MainTabView()
            }
        }
        .transition(.opacity)
        .animation(.easeInOut, value: state.route)
    }
}

// MARK: - Screen wrappers (own their ViewModels with stable identity)

private struct AuthScreen: View {
    @State private var viewModel: AuthViewModel
    init(container: AppContainer) {
        _viewModel = State(initialValue: container.makeAuthViewModel())
    }
    var body: some View { AuthView(viewModel: viewModel) }
}

private struct OnboardingScreen: View {
    @State private var viewModel: OnboardingViewModel
    init(container: AppContainer) {
        _viewModel = State(initialValue: container.makeOnboardingViewModel())
    }
    var body: some View { OnboardingView(viewModel: viewModel) }
}

private struct PlanResultScreen: View {
    @State private var viewModel: PlanResultViewModel
    init(container: AppContainer) {
        let profile = container.appState.pendingProfile ?? FitnessProfile()
        _viewModel = State(initialValue: container.makePlanResultViewModel(profile: profile))
    }
    var body: some View { PlanResultView(viewModel: viewModel) }
}
