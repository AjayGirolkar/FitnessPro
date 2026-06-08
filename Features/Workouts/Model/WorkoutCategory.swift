//
//  WorkoutCategory.swift
//  FitnessPro
//
//  User-facing browse categories. Each maps to a predicate over the raw
//  exercise dataset so the library and the plan engine share one taxonomy.
//

import SwiftUI

enum WorkoutCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case basic
    case intermediate
    case advanced
    case hiit
    case abs
    case cardio

    var id: String { rawValue }

    var title: String {
        switch self {
        case .basic:        return "Basic"
        case .intermediate: return "Intermediate"
        case .advanced:     return "Advanced"
        case .hiit:         return "HIIT"
        case .abs:          return "Abs & Core"
        case .cardio:       return "Cardio"
        }
    }

    var subtitle: String {
        switch self {
        case .basic:        return "Beginner-friendly moves"
        case .intermediate: return "Step up the challenge"
        case .advanced:     return "For seasoned lifters"
        case .hiit:         return "Burn fat fast"
        case .abs:          return "Sculpt your core"
        case .cardio:       return "Boost your endurance"
        }
    }

    var systemImage: String {
        switch self {
        case .basic:        return "figure.walk"
        case .intermediate: return "figure.strengthtraining.traditional"
        case .advanced:     return "figure.strengthtraining.functional"
        case .hiit:         return "flame.fill"
        case .abs:          return "figure.core.training"
        case .cardio:       return "heart.fill"
        }
    }

    var tint: Color {
        switch self {
        case .basic:        return Theme.Colors.accent
        case .intermediate: return Theme.Colors.secondary
        case .advanced:     return Color(hex: 0x9B5CFF)
        case .hiit:         return Theme.Colors.warmAccent
        case .abs:          return Color(hex: 0xFFB020)
        case .cardio:       return Color(hex: 0xFF4D6D)
        }
    }

    /// Predicate selecting matching exercises from the raw dataset.
    func matches(_ exercise: Exercise) -> Bool {
        switch self {
        case .basic:        return exercise.level == .beginner
        case .intermediate: return exercise.level == .intermediate
        case .advanced:     return exercise.level == .advanced
        case .abs:          return exercise.primaryMuscles.contains { $0.lowercased() == "abdominals" }
        case .cardio:       return exercise.category.lowercased() == "cardio"
        case .hiit:
            let cat = exercise.category.lowercased()
            return cat == "plyometrics" || cat == "cardio"
                || (exercise.equipment ?? "").lowercased() == "body only" && exercise.mechanic == "compound"
        }
    }
}
