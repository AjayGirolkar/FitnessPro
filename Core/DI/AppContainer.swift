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
    let health: HealthWriting
    let notifications: NotificationScheduling

    init(
        apiClient: APIClient = URLSessionAPIClient(),
        keyValueStore: KeyValueStore = UserDefaultsStore(),
        exercises: ExerciseProviding = ExerciseRepository(),
        health: HealthWriting = HealthKitService(),
        notifications: NotificationScheduling = LocalNotificationService()
    ) {
        self.apiClient = apiClient
        self.keyValueStore = keyValueStore
        self.exercises = exercises
        self.health = health
        self.notifications = notifications
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
        static let reminders = "settings.reminders"
    }

    // MARK: - Reminders (Profile screen)

    var reminderSettings: ReminderSettings {
        keyValueStore.value(forKey: SettingsKeys.reminders, as: ReminderSettings.self) ?? .default
    }

    /// Persists reminder prefs and (re)schedules local notifications. Requests
    /// permission the first time reminders are switched on.
    func updateReminders(_ settings: ReminderSettings) async {
        keyValueStore.set(settings, forKey: SettingsKeys.reminders)
        if settings.isEnabled {
            let granted = await notifications.requestAuthorization()
            guard granted else { return }
        }
        await notifications.reschedule(settings)
    }

    // MARK: - Health (Profile screen)

    /// Prompts for Health sharing. Returns whether writing is now allowed.
    func enableHealthSync() async -> Bool {
        await health.requestAuthorization()
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
        vm.liveActivity = WorkoutLiveActivityController()
        vm.onComplete = { [appState, health] completion in
            appState.didCompleteWorkout(completion)
            Task { await health.save(completion) }
        }
        return vm
    }

    func makeProgressViewModel() -> ProgressViewModel {
        ProgressViewModel(appState: appState)
    }
}
