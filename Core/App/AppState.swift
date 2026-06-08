//
//  AppState.swift
//  FitnessPro
//
//  Single source of truth for the top-level flow (landing → auth →
//  onboarding → plan → main) and the persisted session (user, profile,
//  active plan). The root coordinator renders whatever `route` says.
//

import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    enum Route: Equatable {
        case landing
        case auth
        case onboarding
        case planResult
        case main
    }

    private(set) var route: Route
    private(set) var user: User?
    private(set) var profile: FitnessProfile?
    private(set) var activePlan: WorkoutPlan?

    /// Completed-workout log, oldest → newest. Basis for streak + progress (TODO #3).
    private(set) var completions: [CompletedWorkout]

    /// Carries the profile from onboarding into the plan-result screen.
    private(set) var pendingProfile: FitnessProfile?

    private let store: KeyValueStore
    private enum Keys {
        static let profile = "app.profile"
        static let plan = "app.activePlan"
        static let completions = "app.completions"
    }

    init(store: KeyValueStore, currentUser: User?) {
        let resolvedPlan = store.value(forKey: Keys.plan, as: WorkoutPlan.self)
        self.store = store
        self.user = currentUser
        self.profile = store.value(forKey: Keys.profile, as: FitnessProfile.self)
        self.activePlan = resolvedPlan
        self.completions = store.value(forKey: Keys.completions, as: [CompletedWorkout].self) ?? []

        // Resume where the user left off (locals only — self not fully init yet).
        if currentUser == nil {
            route = .landing
        } else if resolvedPlan != nil {
            route = .main
        } else {
            route = .onboarding
        }
    }

    // MARK: - Transitions

    func getStarted() { route = .auth }

    func didAuthenticate(_ user: User) {
        self.user = user
        route = activePlan == nil ? .onboarding : .main
    }

    /// Demo entry: always start the full onboarding flow, ignoring any
    /// previously persisted profile/plan so every onboarding screen shows.
    func didAuthenticateAsDemo(_ user: User) {
        self.user = user
        profile = nil
        activePlan = nil
        pendingProfile = nil
        store.remove(forKey: Keys.profile)
        store.remove(forKey: Keys.plan)
        route = .onboarding
    }

    func didFinishOnboarding(_ profile: FitnessProfile) {
        self.profile = profile
        self.pendingProfile = profile
        store.set(profile, forKey: Keys.profile)
        route = .planResult
    }

    func didStartPlan(_ plan: WorkoutPlan) {
        self.activePlan = plan
        store.set(plan, forKey: Keys.plan)
        route = .main
    }

    func regeneratePlan() {
        // From the main app: go back through onboarding to rebuild.
        route = .onboarding
    }

    // MARK: - Workout completion

    func didCompleteWorkout(_ completion: CompletedWorkout) {
        completions.append(completion)
        store.set(completions, forKey: Keys.completions)
    }

    /// Number of consecutive calendar days with a logged workout, counting back
    /// from today (or yesterday — a missed today doesn't break a fresh streak).
    var streak: Int {
        let cal = Calendar.current
        let days = Set(completions.map { cal.startOfDay(for: $0.date) }).sorted(by: >)
        guard let mostRecent = days.first else { return 0 }

        let today = cal.startOfDay(for: .now)
        guard let lag = cal.dateComponents([.day], from: mostRecent, to: today).day, lag <= 1 else {
            return 0
        }

        var count = 1
        var previous = mostRecent
        for day in days.dropFirst() {
            guard let gap = cal.dateComponents([.day], from: day, to: previous).day, gap == 1 else { break }
            count += 1
            previous = day
        }
        return count
    }

    var workoutsLogged: Int { completions.count }

    func signOut(using auth: AuthService) {
        auth.signOut()
        store.remove(forKey: Keys.profile)
        store.remove(forKey: Keys.plan)
        store.remove(forKey: Keys.completions)
        user = nil
        profile = nil
        activePlan = nil
        pendingProfile = nil
        completions = []
        route = .landing
    }
}
