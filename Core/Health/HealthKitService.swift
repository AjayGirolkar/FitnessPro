//
//  HealthKitService.swift
//  FitnessPro
//
//  Writes finished workouts to Apple Health. Protocol-first so the player can
//  log completions without knowing about HealthKit, and so it's mockable in
//  tests / previews. Requires the HealthKit capability + usage strings.
//

import Foundation
import HealthKit

protocol HealthWriting: Sendable {
    /// True once Health permissions have been granted in this app.
    var isAuthorized: Bool { get async }
    /// Prompts for share permission. Returns whether sharing is allowed.
    @discardableResult func requestAuthorization() async -> Bool
    /// Persists a completed workout. No-op when unavailable / unauthorized.
    func save(_ completion: CompletedWorkout) async
}

final class HealthKitService: HealthWriting {
    private let store: HKHealthStore?

    /// Types we write: the workout itself plus active-energy samples.
    private var shareTypes: Set<HKSampleType> {
        var types: Set<HKSampleType> = [HKObjectType.workoutType()]
        if let energy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(energy)
        }
        return types
    }

    init() {
        store = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil
    }

    var isAuthorized: Bool {
        get async {
            guard let store else { return false }
            return store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized
        }
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        guard let store else { return false }
        do {
            try await store.requestAuthorization(toShare: shareTypes, read: [])
            return store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized
        } catch {
            return false
        }
    }

    func save(_ completion: CompletedWorkout) async {
        guard let store, await isAuthorized else { return }

        let end = completion.date
        let start = end.addingTimeInterval(-Double(completion.durationSeconds))
        let kcal = Self.estimatedCalories(for: completion)

        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining

        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        do {
            try await builder.beginCollection(at: start)

            if kcal > 0,
               let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: kcal)
                let sample = HKCumulativeQuantitySample(
                    type: energyType, quantity: quantity, start: start, end: end)
                try await builder.addSamples([sample])
            }

            try await builder.endCollection(at: end)
            _ = try await builder.finishWorkout()
        } catch {
            // Logging failure is non-fatal; the in-app log already has the data.
        }
    }

    /// Rough MET-based estimate for strength training (~5 kcal/min baseline).
    private static func estimatedCalories(for completion: CompletedWorkout) -> Double {
        Double(completion.durationMinutes) * 5
    }
}
