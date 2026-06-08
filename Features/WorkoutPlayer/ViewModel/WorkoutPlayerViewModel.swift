//
//  WorkoutPlayerViewModel.swift
//  FitnessPro
//
//  Drives an active workout: walks a `PlanDay` set-by-set, runs the rest
//  countdown and (for timed moves) the work timer off a single 1-second
//  ticker, tracks the per-set log, and emits a `CompletedWorkout` on finish.
//

import Foundation
import Observation
import UIKit
import AudioToolbox

@MainActor
@Observable
final class WorkoutPlayerViewModel {

    enum Phase: Equatable {
        case exercise
        case resting(secondsRemaining: Int)
        case finished
    }

    // MARK: Inputs
    let day: PlanDay
    private let provider: ExerciseProviding
    var onComplete: ((CompletedWorkout) -> Void)?

    // MARK: State
    private(set) var exercises: [SessionExercise]
    private(set) var exerciseIndex = 0
    private(set) var setIndex = 0
    private(set) var phase: Phase = .exercise
    private(set) var elapsedSeconds = 0

    private(set) var restTotal = 0
    private(set) var timedRemaining = 0
    private(set) var isTimedRunning = false

    private var ticker: Task<Void, Never>?
    private var didFinish = false

    init(day: PlanDay, provider: ExerciseProviding) {
        self.day = day
        self.provider = provider
        self.exercises = day.exercises.map(SessionExercise.init)
    }

    // MARK: - Lifecycle

    func start() {
        guard ticker == nil else { return }
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                self?.onTick()
            }
        }
    }

    func stop() {
        ticker?.cancel()
        ticker = nil
    }

    private func onTick() {
        switch phase {
        case .finished:
            return
        case .resting(let remaining):
            elapsedSeconds += 1
            let next = remaining - 1
            if next <= 0 { restDidFinish() }
            else { phase = .resting(secondsRemaining: next) }
        case .exercise:
            elapsedSeconds += 1
            guard isTimedRunning else { return }
            timedRemaining -= 1
            if timedRemaining <= 0 {
                isTimedRunning = false
                completeSet()
            }
        }
    }

    // MARK: - Derived state

    var currentExercise: SessionExercise { exercises[exerciseIndex] }
    var currentPlanned: PlannedExercise { currentExercise.planned }
    var currentSet: SetEntry { currentExercise.sets[setIndex] }

    var setNumber: Int { setIndex + 1 }
    var setCount: Int { currentPlanned.sets }

    var totalSets: Int { exercises.reduce(0) { $0 + $1.planned.sets } }
    var completedSets: Int { exercises.reduce(0) { $0 + $1.sets.filter(\.isDone).count } }
    var progress: Double { totalSets == 0 ? 0 : Double(completedSets) / Double(totalSets) }

    var imageURL: URL? { provider.exercise(id: currentPlanned.exerciseID)?.imageURLs.first }
    var instructions: [String] { provider.exercise(id: currentPlanned.exerciseID)?.instructions ?? [] }

    var totalVolume: Double {
        exercises.flatMap(\.sets).filter(\.isDone)
            .reduce(0) { $0 + Double($1.reps) * $1.weight }
    }

    var restProgress: Double {
        guard case .resting(let r) = phase, restTotal > 0 else { return 0 }
        return Double(r) / Double(restTotal)
    }

    /// What comes after the current set (for the rest screen preview).
    var upNext: PlannedExercise? {
        guard let (e, _) = nextPosition() else { return nil }
        return exercises[e].planned
    }

    var upNextIsNewExercise: Bool {
        guard let (e, _) = nextPosition() else { return false }
        return e != exerciseIndex
    }

    // MARK: - Editing the current set

    func adjustReps(_ delta: Int) {
        let new = max(0, currentSet.reps + delta)
        exercises[exerciseIndex].sets[setIndex].reps = new
    }

    func adjustWeight(_ delta: Double) {
        let new = max(0, currentSet.weight + delta)
        exercises[exerciseIndex].sets[setIndex].weight = (new * 2).rounded() / 2  // 0.5 step
    }

    // MARK: - Timed work

    func startTimedSet() {
        guard currentPlanned.isTimed, !isTimedRunning else { return }
        timedRemaining = currentPlanned.durationSeconds
        isTimedRunning = true
    }

    // MARK: - Flow

    func completeSet() {
        guard phase == .exercise else { return }
        isTimedRunning = false
        exercises[exerciseIndex].sets[setIndex].isDone = true
        SessionFeedback.setLogged()

        if nextPosition() != nil {
            beginRest()
        } else {
            finish()
        }
    }

    func skipRest() {
        guard case .resting = phase else { return }
        advance()
    }

    func addRest(_ seconds: Int = 15) {
        guard case .resting(let r) = phase else { return }
        restTotal += seconds
        phase = .resting(secondsRemaining: r + seconds)
    }

    /// User bailed out — emit whatever was logged so the streak still counts
    /// if at least one set was done; otherwise discard.
    func endEarly() {
        guard completedSets > 0 else { stop(); return }
        finish()
    }

    private func beginRest() {
        let rest = currentPlanned.restSeconds
        guard rest > 0 else { advance(); return }
        restTotal = rest
        phase = .resting(secondsRemaining: rest)
    }

    private func restDidFinish() {
        SessionFeedback.restEnded()
        advance()
    }

    private func advance() {
        guard let (e, s) = nextPosition() else { finish(); return }
        exerciseIndex = e
        setIndex = s
        phase = .exercise
    }

    /// Next (exercise, set) index pair from the current position, or nil if done.
    private func nextPosition() -> (Int, Int)? {
        if setIndex + 1 < exercises[exerciseIndex].planned.sets {
            return (exerciseIndex, setIndex + 1)
        }
        if exerciseIndex + 1 < exercises.count {
            return (exerciseIndex + 1, 0)
        }
        return nil
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        stop()
        phase = .finished
        SessionFeedback.finished()
        onComplete?(
            CompletedWorkout(
                planDayID: day.id,
                focus: day.focus,
                date: .now,
                durationSeconds: elapsedSeconds,
                totalSets: completedSets,
                totalVolume: totalVolume
            )
        )
    }
}

// MARK: - Haptic / audio cues

enum SessionFeedback {
    static func setLogged() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func restEnded() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        AudioServicesPlaySystemSound(1057)   // short "Tink" cue
    }
    static func finished() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        AudioServicesPlaySystemSound(1025)   // fanfare-ish complete cue
    }
}
