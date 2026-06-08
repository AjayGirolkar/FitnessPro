//
//  WorkoutFocus.swift
//  FitnessPro
//
//  The *type* axis of the workout browser (muscle group / goal). Pairs with
//  Exercise.Level (the *intensity* axis) to drive the two-step browse flow:
//  level → focus → exercise list → start session.
//

import SwiftUI

/// Exercise type the user wants to target. Each maps to a predicate over the
/// raw dataset; intensity comes from the chosen `Exercise.Level`, not here.
enum WorkoutFocus: String, CaseIterable, Identifiable, Codable, Sendable, Hashable {
    case fullBody
    case chest
    case back
    case legs
    case shoulders
    case arms
    case abs
    case cardio
    case hiit

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fullBody:  return "Full Body"
        case .chest:     return "Chest"
        case .back:      return "Back"
        case .legs:      return "Legs"
        case .shoulders: return "Shoulders"
        case .arms:      return "Arms"
        case .abs:       return "Abs & Core"
        case .cardio:    return "Cardio"
        case .hiit:      return "HIIT"
        }
    }

    var subtitle: String {
        switch self {
        case .fullBody:  return "Compound, head-to-toe"
        case .chest:     return "Push strength"
        case .back:      return "Pull & posture"
        case .legs:      return "Quads, glutes, hams"
        case .shoulders: return "Delts & traps"
        case .arms:      return "Biceps & triceps"
        case .abs:       return "Core stability"
        case .cardio:    return "Heart & endurance"
        case .hiit:      return "Burn fat fast"
        }
    }

    var systemImage: String {
        switch self {
        case .fullBody:  return "figure.mixed.cardio"
        case .chest:     return "figure.strengthtraining.traditional"
        case .back:      return "figure.rower"
        case .legs:      return "figure.run"
        case .shoulders: return "figure.arms.open"
        case .arms:      return "dumbbell.fill"
        case .abs:       return "figure.core.training"
        case .cardio:    return "heart.fill"
        case .hiit:      return "flame.fill"
        }
    }

    var tint: Color {
        switch self {
        case .fullBody:  return Theme.Colors.accent
        case .chest:     return Theme.Colors.secondary
        case .back:      return Color(hex: 0x4DA3FF)
        case .legs:      return Color(hex: 0x9B5CFF)
        case .shoulders: return Color(hex: 0x36CFC9)
        case .arms:      return Color(hex: 0xFFB020)
        case .abs:       return Color(hex: 0xFFD23F)
        case .cardio:    return Color(hex: 0xFF4D6D)
        case .hiit:      return Theme.Colors.warmAccent
        }
    }

    /// Primary-muscle keywords used for muscle-based focuses (empty for the
    /// category-based ones, which override `matches` below).
    private var muscleKeywords: Set<String> {
        switch self {
        case .chest:     return ["chest"]
        case .back:      return ["lats", "middle back", "lower back", "traps"]
        case .legs:      return ["quadriceps", "hamstrings", "glutes", "calves"]
        case .shoulders: return ["shoulders"]
        case .arms:      return ["biceps", "triceps", "forearms"]
        case .abs:       return ["abdominals"]
        case .fullBody, .cardio, .hiit: return []
        }
    }

    /// Predicate selecting exercises of this type from the raw dataset.
    func matches(_ exercise: Exercise) -> Bool {
        switch self {
        case .fullBody:
            return exercise.mechanic == "compound"
        case .cardio:
            return exercise.category.lowercased() == "cardio"
        case .hiit:
            let cat = exercise.category.lowercased()
            let bodyOnly = (exercise.equipment ?? "body only").lowercased() == "body only"
            return cat == "plyometrics" || cat == "cardio"
                || (bodyOnly && exercise.mechanic == "compound")
        default:
            let needles = muscleKeywords
            return exercise.primaryMuscles.contains { needles.contains($0.lowercased()) }
        }
    }
}

// MARK: - Exercise.Level browse metadata (intensity axis)

extension Exercise.Level {
    var browseSubtitle: String {
        switch self {
        case .beginner:     return "Light pace · longer rest"
        case .intermediate: return "Step up the challenge"
        case .advanced:     return "High intensity · short rest"
        }
    }

    var systemImage: String {
        switch self {
        case .beginner:     return "figure.walk"
        case .intermediate: return "figure.strengthtraining.traditional"
        case .advanced:     return "figure.strengthtraining.functional"
        }
    }

    var tint: Color {
        switch self {
        case .beginner:     return Theme.Colors.accent
        case .intermediate: return Theme.Colors.secondary
        case .advanced:     return Color(hex: 0x9B5CFF)
        }
    }

    /// Cumulative rank for "this level and easier" filtering.
    var rank: Int {
        switch self {
        case .beginner:     return 0
        case .intermediate: return 1
        case .advanced:     return 2
        }
    }
}

/// A picked (intensity, type) pair — the navigation value for the list screen.
struct BrowseSelection: Hashable {
    let level: Exercise.Level
    let focus: WorkoutFocus

    var title: String { "\(level.displayName) · \(focus.title)" }
}
