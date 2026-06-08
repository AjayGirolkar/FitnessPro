//
//  WorkoutPlan.swift
//  FitnessPro
//
//  The generated program. Produced by the AI generator or the local rule
//  engine, persisted, and rendered on the plan/home screens.
//

import Foundation

struct WorkoutPlan: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    var rationale: String
    var daysPerWeek: Int
    var sessionMinutes: Int
    var days: [PlanDay]
    var source: Source
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        rationale: String,
        daysPerWeek: Int,
        sessionMinutes: Int,
        days: [PlanDay],
        source: Source,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.rationale = rationale
        self.daysPerWeek = daysPerWeek
        self.sessionMinutes = sessionMinutes
        self.days = days
        self.source = source
        self.createdAt = createdAt
    }

    enum Source: String, Codable, Sendable {
        case ai
        case local

        var badge: String {
            switch self {
            case .ai:    return "AI-generated"
            case .local: return "Smart preset"
            }
        }
    }

    var totalExercises: Int { days.reduce(0) { $0 + $1.exercises.count } }
}

struct PlanDay: Identifiable, Codable, Equatable, Sendable {
    var id: UUID = UUID()
    var dayLabel: String        // e.g. "Day 1"
    var focus: String           // e.g. "Upper Body Push"
    var exercises: [PlannedExercise]

    var estimatedMinutes: Int {
        exercises.reduce(0) { $0 + $1.estimatedMinutes }
    }
}

struct PlannedExercise: Identifiable, Codable, Equatable, Sendable {
    var id: UUID = UUID()
    var exerciseID: String      // links to Exercise.id in the dataset
    var name: String            // denormalized for display
    var sets: Int
    var reps: Int               // 0 when the move is time-based
    var restSeconds: Int
    var durationSeconds: Int    // 0 when rep-based

    var isTimed: Bool { durationSeconds > 0 }

    var prescription: String {
        if isTimed { return "\(sets) × \(durationSeconds)s" }
        return "\(sets) × \(reps)"
    }

    /// Rough time cost including rest, for day duration estimates.
    var estimatedMinutes: Int {
        let work = isTimed ? durationSeconds : reps * 4
        let total = sets * (work + restSeconds)
        return max(1, total / 60)
    }
}

extension WorkoutPlan {
    static let preview = WorkoutPlan(
        name: "Lean & Strong — 3 Day",
        rationale: "A balanced full-body split built for a beginner training at home 3 days a week, focused on getting toned.",
        daysPerWeek: 3,
        sessionMinutes: 30,
        days: [
            PlanDay(dayLabel: "Day 1", focus: "Full Body Strength", exercises: [
                PlannedExercise(exerciseID: "Bodyweight_Squat", name: "Bodyweight Squat", sets: 3, reps: 12, restSeconds: 45, durationSeconds: 0),
                PlannedExercise(exerciseID: "Pushups", name: "Pushups", sets: 3, reps: 10, restSeconds: 45, durationSeconds: 0),
                PlannedExercise(exerciseID: "Plank", name: "Plank", sets: 3, reps: 0, restSeconds: 30, durationSeconds: 40)
            ])
        ],
        source: .local
    )
}
