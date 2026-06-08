//
//  WorkoutPlayerViewModelTests.swift
//  FitnessProTests
//
//  Exercises the set-by-set flow without the real timer: completeSet() →
//  rest → skipRest() advances, and the final set fires onComplete with the
//  right summary. Deterministic.
//

import Testing
import Foundation
@testable import FitnessPro

@MainActor
struct WorkoutPlayerViewModelTests {

    /// 2 exercises × 2 sets each.
    private func makeDay() -> PlanDay {
        PlanDay(dayLabel: "Day 1", focus: "Test", exercises: [
            PlannedExercise(exerciseID: "a", name: "A", sets: 2, reps: 10, restSeconds: 30, durationSeconds: 0),
            PlannedExercise(exerciseID: "b", name: "B", sets: 2, reps: 8, restSeconds: 30, durationSeconds: 0)
        ])
    }

    private func makeVM() -> WorkoutPlayerViewModel {
        WorkoutPlayerViewModel(day: makeDay(), provider: ExerciseRepository(seed: []))
    }

    @Test func startsOnFirstSet() {
        let vm = makeVM()
        #expect(vm.phase == .exercise)
        #expect(vm.exerciseIndex == 0)
        #expect(vm.setIndex == 0)
        #expect(vm.totalSets == 4)
        #expect(vm.completedSets == 0)
    }

    @Test func completingSetEntersRest() {
        let vm = makeVM()
        vm.completeSet()
        #expect(vm.completedSets == 1)
        if case .resting = vm.phase {} else { Issue.record("expected resting phase") }
    }

    @Test func skipRestAdvancesToNextSet() {
        let vm = makeVM()
        vm.completeSet()        // ex0 set0 done → rest
        vm.skipRest()
        #expect(vm.phase == .exercise)
        #expect(vm.exerciseIndex == 0)
        #expect(vm.setIndex == 1)
    }

    @Test func advancesAcrossExercises() {
        let vm = makeVM()
        vm.completeSet(); vm.skipRest()   // → ex0 set1
        vm.completeSet(); vm.skipRest()   // → ex1 set0
        #expect(vm.exerciseIndex == 1)
        #expect(vm.setIndex == 0)
    }

    @Test func finalSetFinishesAndReportsSummary() {
        let vm = makeVM()
        var captured: CompletedWorkout?
        vm.onComplete = { captured = $0 }

        vm.adjustWeight(20)               // 20 kg on ex0 set0
        vm.completeSet(); vm.skipRest()
        vm.completeSet(); vm.skipRest()
        vm.completeSet(); vm.skipRest()
        vm.completeSet()                  // last set → finish, no rest

        #expect(vm.phase == .finished)
        #expect(vm.completedSets == 4)
        #expect(captured != nil)
        #expect(captured?.totalSets == 4)
        #expect(captured?.totalVolume == 200)   // 20 kg × 10 reps on the one weighted set
    }

    @Test func adjustRepsAndWeightClampAtZero() {
        let vm = makeVM()
        vm.adjustReps(-100)
        vm.adjustWeight(-100)
        #expect(vm.currentSet.reps == 0)
        #expect(vm.currentSet.weight == 0)
    }

    @Test func pausedTickFreezesElapsed() {
        let vm = makeVM()
        vm.tick()
        #expect(vm.elapsedSeconds == 1)
        vm.togglePause()
        #expect(vm.isPaused)
        vm.tick(); vm.tick()
        #expect(vm.elapsedSeconds == 1)   // frozen while paused
        vm.togglePause()
        vm.tick()
        #expect(vm.elapsedSeconds == 2)   // resumes
    }

    @Test func pauseFreezesRestCountdown() {
        let vm = makeVM()
        vm.completeSet()                  // ex0 set0 → rest (30s)
        guard case .resting(let before) = vm.phase else { Issue.record("expected rest"); return }
        vm.togglePause()
        vm.tick(); vm.tick()
        guard case .resting(let after) = vm.phase else { Issue.record("expected rest"); return }
        #expect(after == before)          // countdown held
    }

    @Test func onCompleteFiresOnlyOnce() {
        let vm = makeVM()
        var count = 0
        vm.onComplete = { _ in count += 1 }
        vm.completeSet(); vm.skipRest()
        vm.completeSet(); vm.skipRest()
        vm.completeSet(); vm.skipRest()
        vm.completeSet()
        vm.endEarly()           // already finished — must not re-fire
        #expect(count == 1)
    }
}
