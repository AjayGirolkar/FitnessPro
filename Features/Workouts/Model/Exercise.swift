//
//  Exercise.swift
//  FitnessPro
//
//  Domain model mirroring the bundled free-exercise-db schema (public
//  domain, ~870 exercises). Images stream from GitHub raw URLs.
//

import Foundation

struct Exercise: Identifiable, Codable, Equatable, Sendable, Hashable {
    let id: String
    let name: String
    let force: String?
    let level: Level
    let mechanic: String?
    let equipment: String?
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let instructions: [String]
    let category: String
    let images: [String]

    enum Level: String, Codable, Sendable, CaseIterable {
        case beginner, intermediate, advanced

        var displayName: String { rawValue.capitalized }

        /// The dataset labels its hardest tier "expert" — map it onto advanced
        /// and fall back gracefully for anything unexpected.
        init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self).lowercased()
            switch raw {
            case "beginner":             self = .beginner
            case "advanced", "expert":   self = .advanced
            default:                     self = .intermediate
            }
        }
    }

    /// Base for streaming exercise images (no bundling needed).
    static let imageBaseURL = URL(string: "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/")!

    var imageURLs: [URL] {
        images.compactMap { URL(string: $0, relativeTo: Self.imageBaseURL)?.absoluteURL }
    }

    var primaryMuscle: String { primaryMuscles.first?.capitalized ?? "Full body" }
    var equipmentDisplay: String { (equipment ?? "Body only").capitalized }
}

extension Exercise {
    static let preview = Exercise(
        id: "Barbell_Squat",
        name: "Barbell Squat",
        force: "push",
        level: .intermediate,
        mechanic: "compound",
        equipment: "barbell",
        primaryMuscles: ["quadriceps"],
        secondaryMuscles: ["glutes", "hamstrings", "calves"],
        instructions: [
            "Set the bar on your upper back and step out of the rack.",
            "Brace your core and descend until thighs are parallel.",
            "Drive through your heels back to standing."
        ],
        category: "strength",
        images: ["Barbell_Squat/0.jpg", "Barbell_Squat/1.jpg"]
    )
}
