//
//  TestExercises.swift
//  FitnessProTests
//
//  Deterministic exercise seed so engine/repository tests stay hermetic
//  (no dependency on the bundled JSON).
//

@testable import FitnessPro

enum TestExercises {
    static func make(
        _ id: String, _ name: String,
        level: Exercise.Level = .beginner,
        equipment: String? = "body only",
        mechanic: String? = "compound",
        category: String = "strength",
        primary: [String]
    ) -> Exercise {
        Exercise(
            id: id, name: name, force: nil, level: level, mechanic: mechanic,
            equipment: equipment, primaryMuscles: primary, secondaryMuscles: [],
            instructions: ["Do \(name)."], category: category, images: ["\(id)/0.jpg"]
        )
    }

    /// Covers legs / push / pull / core at beginner, body-only.
    static let seed: [Exercise] = [
        make("Bodyweight_Squat", "Bodyweight Squat", primary: ["quadriceps"]),
        make("Lunge", "Lunge", primary: ["glutes"]),
        make("Glute_Bridge", "Glute Bridge", mechanic: "isolation", primary: ["glutes"]),
        make("Pushups", "Pushups", primary: ["chest"]),
        make("Pike_Pushup", "Pike Pushup", primary: ["shoulders"]),
        make("Dips", "Dips", primary: ["triceps"]),
        make("Superman", "Superman", mechanic: "isolation", primary: ["lower back"]),
        make("Inverted_Row", "Inverted Row", level: .intermediate, primary: ["middle back"]),
        make("Plank", "Plank", mechanic: "isolation", primary: ["abdominals"]),
        make("Crunches", "Crunches", mechanic: "isolation", primary: ["abdominals"]),
        make("Jumping_Jacks", "Jumping Jacks", category: "cardio", primary: ["quadriceps"]),
        make("Pullups", "Pullups", level: .advanced, primary: ["lats"])
    ]
}
