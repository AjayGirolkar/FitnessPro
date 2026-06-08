//
//  PlanResultViewModel.swift
//  FitnessPro
//
//  Runs plan generation for a finished FitnessProfile and exposes the
//  result. `onStart` persists the plan and advances into the main app.
//

import Foundation
import Observation

@MainActor
@Observable
final class PlanResultViewModel {
    enum State: Equatable {
        case generating
        case loaded(WorkoutPlan)
        case failed(String)
    }

    private(set) var state: State = .generating

    let profile: FitnessProfile
    private let generator: PlanGenerator

    /// Coordinator hook: persist the plan + enter the main app.
    var onStart: (WorkoutPlan) -> Void = { _ in }

    init(profile: FitnessProfile, generator: PlanGenerator) {
        self.profile = profile
        self.generator = generator
    }

    func generate() async {
        state = .generating
        do {
            let plan = try await generator.generatePlan(for: profile)
            state = .loaded(plan)
        } catch {
            state = .failed((error as? LocalizedError)?.errorDescription ?? "Couldn't build your plan.")
        }
    }

    func start() {
        if case let .loaded(plan) = state { onStart(plan) }
    }
}
