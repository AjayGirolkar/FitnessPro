//
//  WorkoutsViewModelTests.swift
//  FitnessProTests
//
//  Swift Testing (Xcode 16+). Drives the ViewModel through its states
//  using injected mock services — no network, deterministic.
//

import Testing
@testable import FitnessPro

@MainActor
struct WorkoutsViewModelTests {

    @Test func loadsWorkoutsOnSuccess() async {
        let vm = WorkoutsViewModel(service: MockWorkoutService(result: .success(Workout.samples)))

        await vm.loadWorkouts()

        #expect(vm.state == .loaded(Workout.samples))
    }

    @Test func showsErrorMessageOnFailure() async {
        let vm = WorkoutsViewModel(service: MockWorkoutService(result: .failure(NetworkError.noConnection)))

        await vm.loadWorkouts()

        #expect(vm.state == .failed(NetworkError.noConnection.userMessage))
    }
}

// MARK: - Test doubles

private struct MockWorkoutService: WorkoutServiceProtocol {
    let result: Result<[Workout], Error>

    func fetchWorkouts() async throws -> [Workout] {
        try result.get()
    }
}
