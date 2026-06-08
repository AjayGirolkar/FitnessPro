//
//  OnboardingViewModel.swift
//  FitnessPro
//
//  Drives the multi-step questionnaire. Owns the FitnessProfile being
//  assembled, validates each step, and hands the finished profile back to
//  the coordinator (which then runs plan generation).
//

import Foundation
import Observation

@MainActor
@Observable
final class OnboardingViewModel {
    enum Step: Int, CaseIterable {
        case goal, level, body, location, equipment, focus, schedule, review

        var title: String {
            switch self {
            case .goal:      return "What's your main goal?"
            case .level:     return "How would you rate your fitness?"
            case .body:      return "Tell us about you"
            case .location:  return "Where will you train?"
            case .equipment: return "What equipment do you have?"
            case .focus:     return "Which areas to focus on?"
            case .schedule:  return "Your weekly schedule"
            case .review:    return "Review & generate"
            }
        }
        var subtitle: String {
            switch self {
            case .goal:      return "We'll shape the whole plan around this"
            case .level:     return "Be honest — we'll meet you where you are"
            case .body:      return "Used to personalize volume & intensity"
            case .location:  return "We'll pick exercises that fit"
            case .equipment: return "Select all that apply"
            case .focus:     return "Pick one or more, or full body"
            case .schedule:  return "How often and how long?"
            case .review:    return "Looks good? Let's build it"
            }
        }
    }

    var profile = FitnessProfile()
    private(set) var step: Step = .goal

    /// Handed the finished profile by the coordinator.
    var onFinished: (FitnessProfile) -> Void = { _ in }

    var progress: Double {
        Double(step.rawValue + 1) / Double(Step.allCases.count)
    }

    var isFirstStep: Bool { step == .goal }
    var isLastStep: Bool { step == .review }

    /// Per-step validation gating the Continue button.
    var canAdvance: Bool {
        switch step {
        case .equipment: return !profile.equipment.isEmpty
        case .focus:     return !profile.targetAreas.isEmpty
        case .body:      return profile.age >= 12 && profile.age <= 100
        default:         return true
        }
    }

    func next() {
        guard canAdvance else { return }
        if isLastStep {
            onFinished(profile)
            return
        }
        if let nextStep = Step(rawValue: step.rawValue + 1) {
            step = nextStep
        }
    }

    func back() {
        if let prev = Step(rawValue: step.rawValue - 1) {
            step = prev
        }
    }

    /// Quick Start path: skip the questionnaire with a preset profile.
    func finishWithPreset(_ preset: FitnessProfile.QuickStart) {
        onFinished(preset.profile)
    }

    // MARK: - Multi-select toggles

    func toggle(_ item: Equipment) {
        if profile.equipment.contains(item) {
            profile.equipment.remove(item)
        } else {
            // "Full gym" is exclusive of individual pieces.
            if item == .fullGym { profile.equipment.removeAll() }
            else { profile.equipment.remove(.fullGym) }
            profile.equipment.insert(item)
        }
    }

    func toggle(_ area: TargetArea) {
        if profile.targetAreas.contains(area) {
            profile.targetAreas.remove(area)
        } else {
            if area == .fullBody { profile.targetAreas.removeAll() }
            else { profile.targetAreas.remove(.fullBody) }
            profile.targetAreas.insert(area)
        }
    }
}
