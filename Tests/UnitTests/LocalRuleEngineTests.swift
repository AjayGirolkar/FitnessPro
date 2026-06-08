//
//  LocalRuleEngineTests.swift
//  FitnessProTests
//

import Testing
@testable import FitnessPro

@Suite("LocalRuleEngine")
struct LocalRuleEngineTests {
    private func engine() -> LocalRuleEngine {
        LocalRuleEngine(provider: ExerciseRepository(seed: TestExercises.seed))
    }

    private func profile(days: Int, level: FitnessLevel, goal: Goal) -> FitnessProfile {
        var p = FitnessProfile()
        p.daysPerWeek = days
        p.fitnessLevel = level
        p.goal = goal
        p.equipment = [.bodyweight]
        p.location = .home
        p.targetAreas = [.fullBody]
        p.sessionMinutes = 30
        return p
    }

    @Test("Builds the requested number of training days")
    func dayCount() async throws {
        let plan = try await engine().generatePlan(for: profile(days: 3, level: .beginner, goal: .getToned))
        #expect(plan.days.count == 3)
        #expect(plan.source == .local)
        #expect(plan.daysPerWeek == 3)
    }

    @Test("Every day has at least one prescribed exercise")
    func nonEmptyDays() async throws {
        let plan = try await engine().generatePlan(for: profile(days: 4, level: .intermediate, goal: .buildMuscle))
        #expect(plan.days.count == 4)
        for day in plan.days { #expect(!day.exercises.isEmpty) }
        #expect(plan.totalExercises > 0)
    }

    @Test("Rep scheme follows the goal")
    func repScheme() async throws {
        let plan = try await engine().generatePlan(for: profile(days: 2, level: .beginner, goal: .buildMuscle))
        let first = try #require(plan.days.first?.exercises.first { !$0.isTimed })
        #expect(first.sets == 4)   // buildMuscle = 4 sets
    }

    @Test("Generation is deterministic by exercise selection")
    func deterministic() async throws {
        let p = profile(days: 3, level: .beginner, goal: .stayHealthy)
        let a = try await engine().generatePlan(for: p)
        let b = try await engine().generatePlan(for: p)
        let namesA = a.days.map { $0.exercises.map(\.name) }
        let namesB = b.days.map { $0.exercises.map(\.name) }
        #expect(namesA == namesB)
    }

    @Test("Timed moves (plank/cardio) use duration, not reps")
    func timedMoves() async throws {
        let plan = try await engine().generatePlan(for: profile(days: 3, level: .beginner, goal: .loseWeight))
        let timed = plan.days.flatMap(\.exercises).filter { $0.name == "Plank" }
        for ex in timed {
            #expect(ex.isTimed)
            #expect(ex.reps == 0)
            #expect(ex.durationSeconds > 0)
        }
    }
}
