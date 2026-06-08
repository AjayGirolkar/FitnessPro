//
//  ClaudePlanGenerator.swift
//  FitnessPro
//
//  AI plan generator. Grounds Claude in the real bundled exercise catalog
//  (so it can't invent moves we don't have), forces structured JSON via
//  tool-use, then resolves returned names back to dataset exercise IDs.
//

import Foundation

struct ClaudePlanGenerator: PlanGenerator {
    let client: AnthropicClient
    let provider: ExerciseProviding

    func generatePlan(for profile: FitnessProfile) async throws -> WorkoutPlan {
        let candidates = candidates(for: profile)
        guard !candidates.isEmpty else { throw PlanGenerationError.noMatchingExercises }

        let tool = AnthropicClient.Tool(
            name: "build_workout_plan",
            description: "Build a personalized weekly workout plan using ONLY the provided exercises.",
            inputSchema: Self.schema
        )

        let data = try await client.toolCall(
            system: Self.systemPrompt,
            user: userPrompt(profile: profile, candidates: candidates),
            tool: tool
        )

        let dto = try decode(data)
        return assemblePlan(from: dto, profile: profile)
    }

    // MARK: - Candidate catalog (level + equipment), capped to keep prompt small

    private func candidates(for profile: FitnessProfile) -> [Exercise] {
        let allowedLevels = levels(upTo: profile.fitnessLevel)
        let allowedEquipment = allowedEquipment(for: profile)
        let pool = provider.all().filter { ex in
            allowedLevels.contains(ex.level) &&
            allowedEquipment.contains((ex.equipment ?? "body only").lowercased())
        }
        // Keep prompt compact: cap at ~90, stable order.
        return Array(pool.sorted { $0.name < $1.name }.prefix(90))
    }

    private func levels(upTo level: FitnessLevel) -> Set<Exercise.Level> {
        switch level {
        case .beginner:     return [.beginner]
        case .intermediate: return [.beginner, .intermediate]
        case .advanced:     return [.beginner, .intermediate, .advanced]
        }
    }

    private func allowedEquipment(for profile: FitnessProfile) -> Set<String> {
        var allowed: Set<String> = ["body only", "other", "none"]
        if profile.equipment.contains(.fullGym) {
            allowed.formUnion(["barbell", "dumbbell", "machine", "cable", "kettlebells", "bands", "e-z curl bar"])
            return allowed
        }
        for item in profile.equipment {
            switch item {
            case .dumbbells:       allowed.insert("dumbbell")
            case .barbell:         allowed.formUnion(["barbell", "e-z curl bar"])
            case .kettlebell:      allowed.insert("kettlebells")
            case .resistanceBands: allowed.insert("bands")
            case .machines:        allowed.formUnion(["machine", "cable"])
            case .bodyweight, .fullGym: break
            }
        }
        return allowed
    }

    // MARK: - Prompt

    private static let systemPrompt = """
    You are an elite strength & conditioning coach. Design safe, effective, \
    progressive weekly workout plans. Use ONLY exercises from the supplied list, \
    referencing each by its exact name. Balance muscle groups across the week, \
    respect the user's level, equipment and time budget, and avoid overtraining. \
    Return your answer solely through the build_workout_plan tool.
    """

    private func userPrompt(profile: FitnessProfile, candidates: [Exercise]) -> String {
        let list = candidates
            .map { "- \($0.name) [\($0.primaryMuscle), \($0.equipmentDisplay)]" }
            .joined(separator: "\n")
        let areas = profile.targetAreas.map(\.title).joined(separator: ", ")
        return """
        Build a \(profile.daysPerWeek)-day weekly plan.

        User profile:
        - Goal: \(profile.goal.title)
        - Fitness level: \(profile.fitnessLevel.title)
        - Location: \(profile.location.title)
        - Days per week: \(profile.daysPerWeek)
        - Session length: ~\(profile.sessionMinutes) minutes
        - Focus areas: \(areas.isEmpty ? "Full body" : areas)
        - Age: \(profile.age), BMI: \(String(format: "%.1f", profile.bmi))
        - Limitations: \(profile.limitations.isEmpty ? "none" : profile.limitations)

        Produce exactly \(profile.daysPerWeek) training days. Each day should have \
        4–7 exercises sized to fit the session length. Use reps for strength moves \
        and durationSeconds for timed moves (planks, cardio); set the unused one to 0.

        Available exercises (use exact names):
        \(list)
        """
    }

    // MARK: - JSON schema for tool-use

    private static let schema: [String: Any] = [
        "type": "object",
        "properties": [
            "name": ["type": "string", "description": "Catchy plan name"],
            "rationale": ["type": "string", "description": "2-3 sentence explanation tailored to the user"],
            "days": [
                "type": "array",
                "items": [
                    "type": "object",
                    "properties": [
                        "focus": ["type": "string"],
                        "exercises": [
                            "type": "array",
                            "items": [
                                "type": "object",
                                "properties": [
                                    "exerciseName": ["type": "string"],
                                    "sets": ["type": "integer"],
                                    "reps": ["type": "integer"],
                                    "restSeconds": ["type": "integer"],
                                    "durationSeconds": ["type": "integer"]
                                ],
                                "required": ["exerciseName", "sets", "reps", "restSeconds", "durationSeconds"]
                            ]
                        ]
                    ],
                    "required": ["focus", "exercises"]
                ]
            ]
        ],
        "required": ["name", "rationale", "days"]
    ]

    // MARK: - Decode + resolve

    private struct PlanDTO: Decodable {
        let name: String
        let rationale: String
        let days: [DayDTO]
        struct DayDTO: Decodable { let focus: String; let exercises: [ExDTO] }
        struct ExDTO: Decodable {
            let exerciseName: String
            let sets: Int
            let reps: Int
            let restSeconds: Int
            let durationSeconds: Int
        }
    }

    private func decode(_ data: Data) throws -> PlanDTO {
        do { return try JSONDecoder().decode(PlanDTO.self, from: data) }
        catch { throw PlanGenerationError.decodingFailed }
    }

    private func assemblePlan(from dto: PlanDTO, profile: FitnessProfile) -> WorkoutPlan {
        let index = Dictionary(provider.all().map { ($0.name.lowercased(), $0) },
                               uniquingKeysWith: { first, _ in first })

        let days = dto.days.enumerated().map { i, day in
            PlanDay(
                dayLabel: "Day \(i + 1)",
                focus: day.focus,
                exercises: day.exercises.map { ex in
                    let match = resolve(name: ex.exerciseName, index: index)
                    return PlannedExercise(
                        exerciseID: match?.id ?? "",
                        name: match?.name ?? ex.exerciseName,
                        sets: max(1, ex.sets),
                        reps: max(0, ex.reps),
                        restSeconds: max(0, ex.restSeconds),
                        durationSeconds: max(0, ex.durationSeconds)
                    )
                }
            )
        }

        return WorkoutPlan(
            name: dto.name,
            rationale: dto.rationale,
            daysPerWeek: profile.daysPerWeek,
            sessionMinutes: profile.sessionMinutes,
            days: days,
            source: .ai
        )
    }

    /// Exact name match, then a forgiving substring match.
    private func resolve(name: String, index: [String: Exercise]) -> Exercise? {
        let key = name.lowercased()
        if let exact = index[key] { return exact }
        return index.first { $0.key.contains(key) || key.contains($0.key) }?.value
    }
}
