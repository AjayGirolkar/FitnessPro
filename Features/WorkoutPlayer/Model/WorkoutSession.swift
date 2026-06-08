//
//  WorkoutSession.swift
//  FitnessPro
//
//  Runtime models for an active workout: the per-set log a user fills in
//  while training, and the immutable summary produced on completion (fed
//  to the streak / progress log).
//

import Foundation

/// One logged set within an exercise. Reps/weight are editable mid-session;
/// `isDone` flips when the user taps "Complete set".
struct SetEntry: Identifiable, Equatable, Sendable {
    let id = UUID()
    var reps: Int
    var weight: Double      // kg; 0 for bodyweight moves
    var isDone: Bool = false
}

/// A planned exercise plus its live set log for the current session.
struct SessionExercise: Identifiable, Equatable, Sendable {
    let planned: PlannedExercise
    var sets: [SetEntry]

    var id: UUID { planned.id }

    init(planned: PlannedExercise) {
        self.planned = planned
        self.sets = (0..<max(1, planned.sets)).map { _ in
            SetEntry(reps: planned.reps, weight: 0)
        }
    }
}

/// Immutable record written when a workout finishes — basis for the streak
/// and the future progress log (see TODO #3).
struct CompletedWorkout: Identifiable, Codable, Equatable, Sendable {
    var id: UUID = UUID()
    var planDayID: UUID
    var focus: String
    var date: Date
    var durationSeconds: Int
    var totalSets: Int
    var totalVolume: Double     // Σ reps × weight over completed sets

    var durationMinutes: Int { max(1, durationSeconds / 60) }
}
