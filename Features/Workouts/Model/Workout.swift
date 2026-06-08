//
//  Workout.swift
//  FitnessPro
//

import Foundation

struct Workout: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let category: Category
    let durationMinutes: Int
    let caloriesBurned: Int

    enum Category: String, Codable, CaseIterable {
        case strength
        case cardio
        case mobility
        case hiit

        var displayName: String {
            switch self {
            case .strength: return "Strength"
            case .cardio:   return "Cardio"
            case .mobility: return "Mobility"
            case .hiit:     return "HIIT"
            }
        }
    }
}

extension Workout {
    /// Sample data for SwiftUI previews and tests.
    static let samples: [Workout] = [
        .init(id: UUID(), name: "Upper Body Push", category: .strength, durationMinutes: 45, caloriesBurned: 320),
        .init(id: UUID(), name: "Morning Run", category: .cardio, durationMinutes: 30, caloriesBurned: 280),
        .init(id: UUID(), name: "Full Body HIIT", category: .hiit, durationMinutes: 20, caloriesBurned: 240)
    ]
}
