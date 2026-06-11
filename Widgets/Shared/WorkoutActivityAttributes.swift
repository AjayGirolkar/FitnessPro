//
//  WorkoutActivityAttributes.swift
//  FitnessPro
//
//  Live Activity contract for the rest timer shown on the Lock Screen and
//  Dynamic Island during a workout. Shared by the app (which starts/updates
//  the activity) and the widget extension (which renders it).
//

import Foundation
import ActivityKit

struct WorkoutActivityAttributes: ActivityAttributes {
    /// Static for the life of the activity.
    let workoutFocus: String
    let totalExercises: Int

    /// Mutable per-update content.
    public struct ContentState: Codable, Hashable {
        var exerciseName: String
        var setLabel: String        // e.g. "Set 2 of 4"
        var restEndsAt: Date        // drives the countdown ring/label
        var isResting: Bool
        var completedExercises: Int
    }
}
