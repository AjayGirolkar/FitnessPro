//
//  ExerciseRepository.swift
//  FitnessPro
//
//  Loads the bundled exercise dataset once and serves filtered queries to
//  the library and the plan engine. Protocol-first for testing/mocking.
//

import Foundation

protocol ExerciseProviding: Sendable {
    func all() -> [Exercise]
    func exercise(id: String) -> Exercise?
    func exercises(in category: WorkoutCategory) -> [Exercise]
    func exercises(level: Exercise.Level?, equipmentBodyOnly: Bool, muscle: String?) -> [Exercise]
}

/// Reads `exercises.json` from the app bundle and caches it. Thread-safe:
/// the cache is built once at init and only read afterwards.
final class ExerciseRepository: ExerciseProviding, @unchecked Sendable {
    private let exercises: [Exercise]
    private let byID: [String: Exercise]

    init(bundle: Bundle = .main) {
        let loaded = Self.load(from: bundle)
        self.exercises = loaded
        self.byID = Dictionary(loaded.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// Test/preview seam: inject a fixed set.
    init(seed: [Exercise]) {
        self.exercises = seed
        self.byID = Dictionary(seed.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    func all() -> [Exercise] { exercises }

    func exercise(id: String) -> Exercise? { byID[id] }

    func exercises(in category: WorkoutCategory) -> [Exercise] {
        exercises.filter(category.matches)
    }

    func exercises(level: Exercise.Level?, equipmentBodyOnly: Bool, muscle: String?) -> [Exercise] {
        exercises.filter { ex in
            if let level, ex.level != level { return false }
            if equipmentBodyOnly {
                let eq = (ex.equipment ?? "body only").lowercased()
                guard eq == "body only" || eq == "none" else { return false }
            }
            if let muscle {
                let needle = muscle.lowercased()
                guard ex.primaryMuscles.contains(where: { $0.lowercased() == needle }) else { return false }
            }
            return true
        }
    }

    // MARK: - Loading
    private static func load(from bundle: Bundle) -> [Exercise] {
        guard let url = bundle.url(forResource: "exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            assertionFailure("exercises.json missing from bundle")
            return []
        }
        do {
            return try JSONDecoder().decode([Exercise].self, from: data)
        } catch {
            assertionFailure("Failed to decode exercises.json: \(error)")
            return []
        }
    }
}
