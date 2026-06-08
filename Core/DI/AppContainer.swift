//
//  AppContainer.swift
//  FitnessPro
//
//  Composition root. Owns shared singletons (API client, stores, exercise
//  catalog, auth, app state) and builds ViewModels with dependencies and
//  navigation callbacks wired in. No 3rd-party DI.
//

import Foundation
import Observation

@MainActor
@Observable
final class AppContainer {
    // MARK: Shared infrastructure
    let apiClient: APIClient
    let keyValueStore: KeyValueStore
    let authService: AuthService
    let exercises: ExerciseProviding
    let playlists: PlaylistStore
    let appState: AppState

    init(
        apiClient: APIClient = URLSessionAPIClient(),
        keyValueStore: KeyValueStore = UserDefaultsStore(),
        exercises: ExerciseProviding = ExerciseRepository()
    ) {
        self.apiClient = apiClient
        self.keyValueStore = keyValueStore
        self.exercises = exercises
        self.playlists = PlaylistStore(store: keyValueStore)
        let auth = MockAuthService(store: keyValueStore)
        self.authService = auth
        self.appState = AppState(store: keyValueStore, currentUser: auth.currentUser())
    }

    // MARK: - AI configuration

    /// API key from runtime settings first, then Info.plist. Empty ⇒ no AI.
    private var anthropicAPIKey: String {
        if let stored: String = keyValueStore.value(forKey: SettingsKeys.anthropicKey, as: String.self),
           !stored.isEmpty {
            return stored
        }
        let plist = (Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String) ?? ""
        return plist
    }

    private var anthropicModel: String {
        keyValueStore.value(forKey: SettingsKeys.anthropicModel, as: String.self)
            ?? "claude-haiku-4-5-20251001"
    }

    enum SettingsKeys {
        static let anthropicKey = "settings.anthropicKey"
        static let anthropicModel = "settings.anthropicModel"
    }

    // MARK: - Settings (Profile screen)

    /// The user-entered key override (excludes the Info.plist fallback).
    var storedAPIKey: String {
        keyValueStore.value(forKey: SettingsKeys.anthropicKey, as: String.self) ?? ""
    }

    func updateAPIKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { keyValueStore.remove(forKey: SettingsKeys.anthropicKey) }
        else { keyValueStore.set(trimmed, forKey: SettingsKeys.anthropicKey) }
    }

    /// True when *any* key is available (settings override or Info.plist).
    var aiEnabled: Bool { !anthropicAPIKey.isEmpty }

    // MARK: - Plan generation

    func makePlanGenerator() -> PlanGenerator {
        let local = LocalRuleEngine(provider: exercises)
        let key = anthropicAPIKey
        let ai: PlanGenerator? = key.isEmpty
            ? nil
            : ClaudePlanGenerator(client: AnthropicClient(apiKey: key, model: anthropicModel),
                                  provider: exercises)
        return PlanGeneratorService(ai: ai, local: local)
    }

    // MARK: - Feature factories

    func makeAuthViewModel() -> AuthViewModel {
        let vm = AuthViewModel(service: authService)
        vm.onAuthenticated = { [appState] user in appState.didAuthenticate(user) }
        vm.onDemoAuthenticated = { [appState] user in appState.didAuthenticateAsDemo(user) }
        return vm
    }

    func makeOnboardingViewModel() -> OnboardingViewModel {
        let vm = OnboardingViewModel()
        vm.onFinished = { [appState] profile in appState.didFinishOnboarding(profile) }
        return vm
    }

    func makePlanResultViewModel(profile: FitnessProfile) -> PlanResultViewModel {
        let vm = PlanResultViewModel(profile: profile, generator: makePlanGenerator())
        vm.onStart = { [appState] plan in appState.didStartPlan(plan) }
        return vm
    }

    func makeWorkoutsViewModel() -> WorkoutsViewModel {
        WorkoutsViewModel(service: WorkoutService(client: apiClient))
    }

    func makeWorkoutLibraryViewModel() -> WorkoutLibraryViewModel {
        WorkoutLibraryViewModel(provider: exercises, playlistStore: playlists)
    }

    func makeWorkoutPlayerViewModel(day: PlanDay) -> WorkoutPlayerViewModel {
        let vm = WorkoutPlayerViewModel(day: day, provider: exercises)
        vm.onComplete = { [appState] completion in appState.didCompleteWorkout(completion) }
        return vm
    }
}
