//
//  SessionBuilder.swift
//  FitnessPro
//
//  Turns a browsed/curated list of exercises into a runnable `PlanDay` so the
//  existing WorkoutPlayer can drive it set-by-set. Intensity (sets/reps/rest)
//  is derived from the chosen level; timed moves are detected by category/name.
//

import Foundation

struct SessionBuilder {

    /// Per-level prescription. Lower levels → fewer sets, more rest.
    struct Scheme: Equatable {
        let sets: Int
        let reps: Int
        let rest: Int
    }

    func scheme(for level: Exercise.Level) -> Scheme {
        switch level {
        case .beginner:     return Scheme(sets: 2, reps: 12, rest: 60)
        case .intermediate: return Scheme(sets: 3, reps: 12, rest: 45)
        case .advanced:     return Scheme(sets: 4, reps: 10, rest: 30)
        }
    }

    /// Build a runnable day from the given exercises at the given intensity.
    /// Returns `nil` when there is nothing to run.
    func makeDay(focus: String, exercises: [Exercise], level: Exercise.Level) -> PlanDay? {
        guard !exercises.isEmpty else { return nil }
        let s = scheme(for: level)
        let planned = exercises.map { ex -> PlannedExercise in
            let timed = Self.isTimed(ex)
            return PlannedExercise(
                exerciseID: ex.id,
                name: ex.name,
                sets: s.sets,
                reps: timed ? 0 : s.reps,
                restSeconds: s.rest,
                durationSeconds: timed ? 40 : 0
            )
        }
        return PlanDay(dayLabel: focus, focus: focus, exercises: planned)
    }

    /// Cardio and isometric holds run on the clock rather than reps.
    static func isTimed(_ exercise: Exercise) -> Bool {
        if exercise.category.lowercased() == "cardio" { return true }
        let n = exercise.name.lowercased()
        return n.contains("plank") || n.contains("hold") || n.contains("wall sit")
    }
}
