//
//  FitnessProfile.swift
//  FitnessPro
//
//  Everything the onboarding quiz collects. Feeds the plan generator
//  (AI + local rule engine) and the Profile screen.
//

import Foundation

struct FitnessProfile: Codable, Equatable, Sendable {
    var goal: Goal = .stayHealthy
    var gender: Gender = .preferNotToSay
    var age: Int = 28
    var heightCm: Double = 172
    var weightKg: Double = 72
    var unitSystem: UnitSystem = .metric
    var fitnessLevel: FitnessLevel = .beginner
    var location: WorkoutLocation = .home
    var equipment: Set<Equipment> = [.bodyweight]
    var daysPerWeek: Int = 3
    var sessionMinutes: Int = 30
    var targetAreas: Set<TargetArea> = [.fullBody]
    var limitations: String = ""

    /// Body Mass Index — handy for plan rationale.
    var bmi: Double {
        let h = heightCm / 100
        guard h > 0 else { return 0 }
        return weightKg / (h * h)
    }
}

// MARK: - Choice enums

enum Goal: String, Codable, CaseIterable, Identifiable, Sendable {
    case loseWeight, buildMuscle, getToned, improveEndurance, stayHealthy
    var id: String { rawValue }

    var title: String {
        switch self {
        case .loseWeight:       return "Lose weight"
        case .buildMuscle:      return "Build muscle"
        case .getToned:         return "Get toned"
        case .improveEndurance: return "Improve endurance"
        case .stayHealthy:      return "Stay healthy"
        }
    }
    var subtitle: String {
        switch self {
        case .loseWeight:       return "Burn fat, stay lean"
        case .buildMuscle:      return "Gain strength & size"
        case .getToned:         return "Define and sculpt"
        case .improveEndurance: return "Boost stamina & cardio"
        case .stayHealthy:      return "Move more, feel good"
        }
    }
    var systemImage: String {
        switch self {
        case .loseWeight:       return "flame.fill"
        case .buildMuscle:      return "dumbbell.fill"
        case .getToned:         return "figure.cooldown"
        case .improveEndurance: return "figure.run"
        case .stayHealthy:      return "heart.fill"
        }
    }
}

enum Gender: String, Codable, CaseIterable, Identifiable, Sendable {
    case male, female, other, preferNotToSay
    var id: String { rawValue }
    var title: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        case .preferNotToSay: return "Prefer not to say"
        }
    }
}

enum FitnessLevel: String, Codable, CaseIterable, Identifiable, Sendable {
    case beginner, intermediate, advanced
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var subtitle: String {
        switch self {
        case .beginner:     return "New or returning to exercise"
        case .intermediate: return "Train semi-regularly"
        case .advanced:     return "Train consistently & hard"
        }
    }
    var exerciseLevel: Exercise.Level {
        switch self {
        case .beginner:     return .beginner
        case .intermediate: return .intermediate
        case .advanced:     return .advanced
        }
    }
}

enum WorkoutLocation: String, Codable, CaseIterable, Identifiable, Sendable {
    case home, gym, outdoor
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var systemImage: String {
        switch self {
        case .home:    return "house.fill"
        case .gym:     return "building.2.fill"
        case .outdoor: return "tree.fill"
        }
    }
}

enum Equipment: String, Codable, CaseIterable, Identifiable, Sendable {
    case bodyweight, dumbbells, barbell, kettlebell, resistanceBands, machines, fullGym
    var id: String { rawValue }
    var title: String {
        switch self {
        case .bodyweight:      return "Bodyweight"
        case .dumbbells:       return "Dumbbells"
        case .barbell:         return "Barbell"
        case .kettlebell:      return "Kettlebell"
        case .resistanceBands: return "Resistance bands"
        case .machines:        return "Machines"
        case .fullGym:         return "Full gym"
        }
    }
    var systemImage: String {
        switch self {
        case .bodyweight:      return "figure.arms.open"
        case .dumbbells:       return "dumbbell.fill"
        case .barbell:         return "figure.strengthtraining.traditional"
        case .kettlebell:      return "figure.kickboxing"
        case .resistanceBands: return "bolt.horizontal.fill"
        case .machines:        return "gearshape.2.fill"
        case .fullGym:         return "building.2.fill"
        }
    }
}

enum TargetArea: String, Codable, CaseIterable, Identifiable, Sendable {
    case fullBody, chest, back, shoulders, arms, core, legs, glutes
    var id: String { rawValue }
    var title: String {
        switch self {
        case .fullBody: return "Full body"
        default:        return rawValue.capitalized
        }
    }
    /// Muscle keywords (free-exercise-db vocabulary) for this area.
    var muscleKeywords: [String] {
        switch self {
        case .fullBody:  return []
        case .chest:     return ["chest"]
        case .back:      return ["lats", "middle back", "lower back", "traps"]
        case .shoulders: return ["shoulders"]
        case .arms:      return ["biceps", "triceps", "forearms"]
        case .core:      return ["abdominals"]
        case .legs:      return ["quadriceps", "hamstrings", "calves"]
        case .glutes:    return ["glutes"]
        }
    }
}

enum UnitSystem: String, Codable, CaseIterable, Identifiable, Sendable {
    case metric, imperial
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

// MARK: - Quick Start presets (generic, reusable plans)

extension FitnessProfile {
    enum QuickStart: String, CaseIterable, Identifiable {
        case slimDown, average, healthyAndFit
        var id: String { rawValue }

        var title: String {
            switch self {
            case .slimDown:      return "I'm slim — tone up"
            case .average:       return "I'm average — get fitter"
            case .healthyAndFit: return "I'm healthy — push harder"
            }
        }
        var subtitle: String {
            switch self {
            case .slimDown:      return "Light strength + conditioning"
            case .average:       return "Balanced full-body program"
            case .healthyAndFit: return "Higher volume & intensity"
            }
        }
        var systemImage: String {
            switch self {
            case .slimDown:      return "figure.cooldown"
            case .average:       return "figure.mixed.cardio"
            case .healthyAndFit: return "figure.highintensity.intervaltraining"
            }
        }

        var profile: FitnessProfile {
            var p = FitnessProfile()
            p.location = .home
            p.equipment = [.bodyweight]
            p.targetAreas = [.fullBody]
            switch self {
            case .slimDown:
                p.goal = .getToned; p.fitnessLevel = .beginner
                p.daysPerWeek = 3; p.sessionMinutes = 30
            case .average:
                p.goal = .stayHealthy; p.fitnessLevel = .intermediate
                p.daysPerWeek = 4; p.sessionMinutes = 40
            case .healthyAndFit:
                p.goal = .buildMuscle; p.fitnessLevel = .advanced
                p.daysPerWeek = 5; p.sessionMinutes = 50
            }
            return p
        }
    }
}
