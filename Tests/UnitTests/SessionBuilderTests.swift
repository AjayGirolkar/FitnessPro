//
//  SessionBuilderTests.swift
//  FitnessProTests
//
//  Verifies the Exercise[] → PlanDay mapping: per-level intensity, timed-move
//  detection, and order/count preservation.
//

import Testing
@testable import FitnessPro

@Suite("SessionBuilder")
struct SessionBuilderTests {
    private let builder = SessionBuilder()

    @Test func schemePerLevel() {
        #expect(builder.scheme(for: .beginner)     == SessionBuilder.Scheme(sets: 2, reps: 12, rest: 60))
        #expect(builder.scheme(for: .intermediate) == SessionBuilder.Scheme(sets: 3, reps: 12, rest: 45))
        #expect(builder.scheme(for: .advanced)     == SessionBuilder.Scheme(sets: 4, reps: 10, rest: 30))
    }

    @Test func emptyReturnsNil() {
        #expect(builder.makeDay(focus: "X", exercises: [], level: .beginner) == nil)
    }

    @Test func repBasedMovePrescription() {
        let squat = TestExercises.make("S", "Squat", primary: ["quadriceps"])
        let pe = builder.makeDay(focus: "Legs", exercises: [squat], level: .advanced)?.exercises.first
        #expect(pe?.isTimed == false)
        #expect(pe?.sets == 4)
        #expect(pe?.reps == 10)
        #expect(pe?.durationSeconds == 0)
        #expect(pe?.exerciseID == "S")
        #expect(pe?.name == "Squat")
    }

    @Test func plankIsTimed() {
        let plank = TestExercises.make("Plank", "Plank", mechanic: "isolation", primary: ["abdominals"])
        let pe = builder.makeDay(focus: "Core", exercises: [plank], level: .beginner)?.exercises.first
        #expect(pe?.isTimed == true)
        #expect(pe?.durationSeconds == 40)
        #expect(pe?.reps == 0)
        #expect(pe?.restSeconds == 60)
    }

    @Test func cardioIsTimed() {
        let jj = TestExercises.make("JJ", "Jumping Jacks", category: "cardio", primary: ["quadriceps"])
        let pe = builder.makeDay(focus: "Cardio", exercises: [jj], level: .beginner)?.exercises.first
        #expect(pe?.isTimed == true)
    }

    @Test func preservesOrderAndCount() {
        let day = builder.makeDay(focus: "Mix", exercises: TestExercises.seed, level: .beginner)
        #expect(day?.exercises.count == TestExercises.seed.count)
        #expect(day?.exercises.map(\.exerciseID) == TestExercises.seed.map(\.id))
        #expect(day?.focus == "Mix")
    }
}
