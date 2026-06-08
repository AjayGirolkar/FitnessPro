//
//  LocalRuleEngine.swift
//  FitnessPro
//
//  Deterministic, offline plan builder. Maps a FitnessProfile to a split,
//  rep scheme and exercise selection drawn from the bundled dataset. No
//  network, no API key — the always-available fallback.
//

import Foundation

struct LocalRuleEngine: PlanGenerator {
    let provider: ExerciseProviding

    func generatePlan(for profile: FitnessProfile) async throws -> WorkoutPlan {
        let pool = candidatePool(for: profile)
        guard !pool.isEmpty else { throw PlanGenerationError.noMatchingExercises }

        let scheme = repScheme(for: profile.goal)
        let perDay = exercisesPerDay(minutes: profile.sessionMinutes)
        let segments = split(for: profile)

        var days: [PlanDay] = []
        for (index, segment) in segments.enumerated() {
            // Dedupe within a day only — the same lift may recur on another day.
            var used = Set<String>()
            let picks = select(count: perDay, buckets: segment.buckets, from: pool, used: &used)
            let exercises = picks.map { prescribe($0, scheme: scheme) }
            days.append(PlanDay(dayLabel: "Day \(index + 1)", focus: segment.focus, exercises: exercises))
        }

        return WorkoutPlan(
            name: planName(for: profile),
            rationale: rationale(for: profile),
            daysPerWeek: profile.daysPerWeek,
            sessionMinutes: profile.sessionMinutes,
            days: days,
            source: .local
        )
    }

    // MARK: - Candidate pool (level + equipment filter)

    private func candidatePool(for profile: FitnessProfile) -> [Exercise] {
        let allowedLevels = levels(upTo: profile.fitnessLevel)
        let allowedEquipment = allowedEquipment(for: profile)
        return provider.all().filter { ex in
            guard allowedLevels.contains(ex.level) else { return false }
            let eq = (ex.equipment ?? "body only").lowercased()
            return allowedEquipment.contains(eq)
        }
    }

    private func levels(upTo level: FitnessLevel) -> Set<Exercise.Level> {
        switch level {
        case .beginner:     return [.beginner]
        case .intermediate: return [.beginner, .intermediate]
        case .advanced:     return [.beginner, .intermediate, .advanced]
        }
    }

    private func allowedEquipment(for profile: FitnessProfile) -> Set<String> {
        var allowed: Set<String> = ["body only", "other", "none", "foam roll"]
        if profile.equipment.contains(.fullGym) {
            allowed.formUnion(["barbell", "dumbbell", "machine", "cable", "kettlebells",
                               "bands", "medicine ball", "exercise ball", "e-z curl bar"])
            return allowed
        }
        for item in profile.equipment {
            switch item {
            case .bodyweight:      break // already included
            case .dumbbells:       allowed.insert("dumbbell")
            case .barbell:         allowed.formUnion(["barbell", "e-z curl bar"])
            case .kettlebell:      allowed.insert("kettlebells")
            case .resistanceBands: allowed.insert("bands")
            case .machines:        allowed.formUnion(["machine", "cable"])
            case .fullGym:         break
            }
        }
        return allowed
    }

    // MARK: - Rep schemes

    private struct Scheme { let sets: Int; let reps: Int; let rest: Int }

    private func repScheme(for goal: Goal) -> Scheme {
        switch goal {
        case .buildMuscle:      return Scheme(sets: 4, reps: 9,  rest: 90)
        case .loseWeight:       return Scheme(sets: 3, reps: 15, rest: 30)
        case .getToned:         return Scheme(sets: 3, reps: 12, rest: 45)
        case .improveEndurance: return Scheme(sets: 3, reps: 18, rest: 30)
        case .stayHealthy:      return Scheme(sets: 3, reps: 12, rest: 45)
        }
    }

    private func exercisesPerDay(minutes: Int) -> Int {
        // ~6 min per exercise incl. rest; clamp to a sensible range.
        min(8, max(4, minutes / 6))
    }

    // MARK: - Split selection

    private struct Segment { let focus: String; let buckets: [[String]] }

    private let legs   = ["quadriceps", "hamstrings", "glutes", "calves"]
    private let push   = ["chest", "shoulders", "triceps"]
    private let pull   = ["lats", "middle back", "biceps", "lower back", "traps"]
    private let core   = ["abdominals"]

    private func split(for profile: FitnessProfile) -> [Segment] {
        // Targeted areas chosen explicitly → build every day around them.
        if !profile.targetAreas.contains(.fullBody), !profile.targetAreas.isEmpty {
            let buckets = profile.targetAreas.map { $0.muscleKeywords }.filter { !$0.isEmpty }
            let focus = "Targeted: " + profile.targetAreas.map(\.title).joined(separator: ", ")
            let merged = buckets.isEmpty ? [legs, push, pull, core] : buckets
            return Array(repeating: Segment(focus: focus, buckets: merged), count: profile.daysPerWeek)
        }

        let fullBody = Segment(focus: "Full Body", buckets: [legs, push, pull, core])
        let upper = Segment(focus: "Upper Body", buckets: [["chest"], ["lats", "middle back"], ["shoulders"], ["biceps"], ["triceps"]])
        let lower = Segment(focus: "Lower Body", buckets: [["quadriceps"], ["hamstrings"], ["glutes"], ["calves"], core])
        let pushDay = Segment(focus: "Push", buckets: [["chest"], ["shoulders"], ["triceps"]])
        let pullDay = Segment(focus: "Pull", buckets: [["lats", "middle back"], ["biceps"], ["lower back", "traps"]])
        let legDay = Segment(focus: "Legs", buckets: [["quadriceps"], ["hamstrings"], ["glutes"], ["calves"]])

        switch profile.daysPerWeek {
        case ...2:  return [fullBody, fullBody]
        case 3:     return [fullBody, fullBody, fullBody]
        case 4:     return [upper, lower, upper, lower]
        case 5:     return [pushDay, pullDay, legDay, upper, lower]
        default:    return [pushDay, pullDay, legDay, pushDay, pullDay, legDay]
        }
    }

    // MARK: - Exercise selection (round-robin across muscle buckets)

    private func select(count: Int, buckets: [[String]], from pool: [Exercise], used: inout Set<String>) -> [Exercise] {
        guard !buckets.isEmpty else { return [] }
        var picked: [Exercise] = []
        var bucketIndex = 0
        var safety = count * buckets.count + buckets.count

        while picked.count < count, safety > 0 {
            safety -= 1
            let muscles = buckets[bucketIndex % buckets.count]
            bucketIndex += 1
            if let choice = bestMatch(for: muscles, in: pool, excluding: used) {
                used.insert(choice.id)
                picked.append(choice)
            }
        }

        // If buckets ran dry (small pool), backfill with any unused exercise.
        if picked.count < count {
            for ex in pool where !used.contains(ex.id) && picked.count < count {
                used.insert(ex.id); picked.append(ex)
            }
        }
        return picked
    }

    private func bestMatch(for muscles: [String], in pool: [Exercise], excluding used: Set<String>) -> Exercise? {
        let needles = Set(muscles.map { $0.lowercased() })
        let matches = pool.filter { ex in
            !used.contains(ex.id) &&
            ex.primaryMuscles.contains { needles.contains($0.lowercased()) }
        }
        // Compound moves first, then stable alphabetical for determinism.
        return matches.sorted { a, b in
            let ac = a.mechanic == "compound", bc = b.mechanic == "compound"
            if ac != bc { return ac }
            return a.name < b.name
        }.first
    }

    // MARK: - Prescription

    private func prescribe(_ exercise: Exercise, scheme: Scheme) -> PlannedExercise {
        let timed = isTimed(exercise)
        return PlannedExercise(
            exerciseID: exercise.id,
            name: exercise.name,
            sets: scheme.sets,
            reps: timed ? 0 : scheme.reps,
            restSeconds: scheme.rest,
            durationSeconds: timed ? 40 : 0
        )
    }

    private func isTimed(_ exercise: Exercise) -> Bool {
        if exercise.category.lowercased() == "cardio" { return true }
        let n = exercise.name.lowercased()
        return n.contains("plank") || n.contains("hold") || n.contains("wall sit")
    }

    // MARK: - Copy

    private func planName(for profile: FitnessProfile) -> String {
        "\(profile.goal.title) — \(profile.daysPerWeek) Day"
    }

    private func rationale(for profile: FitnessProfile) -> String {
        let loc = profile.location.title.lowercased()
        return "A \(profile.fitnessLevel.title.lowercased()) program built around your goal to \(profile.goal.title.lowercased()), training \(profile.daysPerWeek)× per week at \(loc) in ~\(profile.sessionMinutes)-minute sessions."
    }
}
