//
//  PlanGenerator.swift
//  FitnessPro
//
//  Abstraction for turning a FitnessProfile into a WorkoutPlan. Two impls:
//  ClaudePlanGenerator (AI) and LocalRuleEngine (offline). PlanGeneratorService
//  picks AI when a key exists and falls back to the rule engine on any error.
//

import Foundation

protocol PlanGenerator: Sendable {
    func generatePlan(for profile: FitnessProfile) async throws -> WorkoutPlan
}

enum PlanGenerationError: LocalizedError {
    case missingAPIKey
    case emptyResponse
    case decodingFailed
    case noMatchingExercises

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:        return "No AI key configured."
        case .emptyResponse:        return "The AI returned no plan."
        case .decodingFailed:       return "Couldn't read the AI plan."
        case .noMatchingExercises:  return "No exercises matched your setup."
        }
    }
}

/// Tries the AI generator first (when available); falls back to the local
/// rule engine so the user *always* gets a plan, even offline.
struct PlanGeneratorService: PlanGenerator {
    let ai: PlanGenerator?
    let local: PlanGenerator

    func generatePlan(for profile: FitnessProfile) async throws -> WorkoutPlan {
        if let ai {
            do {
                return try await ai.generatePlan(for: profile)
            } catch {
                // AI failed (no key / network / decoding) — degrade gracefully.
                return try await local.generatePlan(for: profile)
            }
        }
        return try await local.generatePlan(for: profile)
    }
}
