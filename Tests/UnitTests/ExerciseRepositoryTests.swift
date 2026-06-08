//
//  ExerciseRepositoryTests.swift
//  FitnessProTests
//

import Testing
@testable import FitnessPro

@Suite("ExerciseRepository")
struct ExerciseRepositoryTests {
    private let repo = ExerciseRepository(seed: TestExercises.seed)

    @Test("Loads the seeded catalog")
    func loads() {
        #expect(repo.all().count == TestExercises.seed.count)
    }

    @Test("Looks up by id")
    func lookup() {
        #expect(repo.exercise(id: "Pushups")?.name == "Pushups")
        #expect(repo.exercise(id: "missing") == nil)
    }

    @Test("Filters by category — Abs returns abdominal moves")
    func absCategory() {
        let abs = repo.exercises(in: .abs)
        #expect(abs.allSatisfy { $0.primaryMuscles.contains("abdominals") })
        #expect(abs.contains { $0.name == "Plank" })
    }

    @Test("Cardio category returns cardio-tagged moves")
    func cardioCategory() {
        let cardio = repo.exercises(in: .cardio)
        #expect(cardio.contains { $0.name == "Jumping Jacks" })
    }

    @Test("Compound filter by level + equipment + muscle")
    func compoundFilter() {
        let results = repo.exercises(level: .beginner, equipmentBodyOnly: true, muscle: "chest")
        #expect(results.contains { $0.name == "Pushups" })
        #expect(results.allSatisfy { $0.level == .beginner })
    }
}
