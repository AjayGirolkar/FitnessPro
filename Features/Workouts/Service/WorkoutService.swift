//
//  WorkoutService.swift
//  FitnessPro
//
//  Feature-level data source. Maps endpoints to domain models so the
//  ViewModel never touches networking details. Protocol enables mocking.
//

import Foundation

protocol WorkoutServiceProtocol: Sendable {
    func fetchWorkouts() async throws -> [Workout]
}

struct WorkoutService: WorkoutServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchWorkouts() async throws -> [Workout] {
        // TODO: Replace stub with real endpoint once the API is live.
        // let endpoint = Endpoint(path: "/v1/workouts")
        // return try await client.send(endpoint, as: [Workout].self)

        try await Task.sleep(for: .milliseconds(400)) // simulate latency
        return Workout.samples
    }
}
