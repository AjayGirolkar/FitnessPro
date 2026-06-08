//
//  OnboardingViewModelTests.swift
//  FitnessProTests
//

import Testing
@testable import FitnessPro

@MainActor
@Suite("OnboardingViewModel")
struct OnboardingViewModelTests {

    @Test("Steps advance and report progress")
    func progression() {
        let vm = OnboardingViewModel()
        #expect(vm.step == .goal)
        #expect(vm.isFirstStep)
        vm.next()
        #expect(vm.step == .level)
        vm.back()
        #expect(vm.step == .goal)
    }

    @Test("Equipment step gates Continue until a choice is made")
    func equipmentValidation() {
        let vm = OnboardingViewModel()
        vm.profile.equipment = []
        // Walk to the equipment step.
        while vm.step != .equipment { vm.next() }
        #expect(vm.canAdvance == false)
        vm.toggle(.dumbbells)
        #expect(vm.canAdvance == true)
    }

    @Test("Full gym is exclusive of individual equipment")
    func fullGymExclusive() {
        let vm = OnboardingViewModel()
        vm.toggle(.dumbbells)
        vm.toggle(.barbell)
        vm.toggle(.fullGym)
        #expect(vm.profile.equipment == [.fullGym])
    }

    @Test("Full body is exclusive of specific target areas")
    func fullBodyExclusive() {
        let vm = OnboardingViewModel()
        vm.toggle(.chest)
        vm.toggle(.fullBody)
        #expect(vm.profile.targetAreas == [.fullBody])
        vm.toggle(.arms)
        #expect(vm.profile.targetAreas == [.arms])
    }

    @Test("Finishing the last step hands back the profile")
    func finishCallsCallback() {
        let vm = OnboardingViewModel()
        var captured: FitnessProfile?
        vm.onFinished = { captured = $0 }
        vm.profile.goal = .buildMuscle
        while !vm.isLastStep { vm.next() }
        vm.next() // review → finish
        #expect(captured?.goal == .buildMuscle)
    }

    @Test("Quick Start preset finishes immediately")
    func quickStart() {
        let vm = OnboardingViewModel()
        var captured: FitnessProfile?
        vm.onFinished = { captured = $0 }
        vm.finishWithPreset(.average)
        #expect(captured?.daysPerWeek == 4)
        #expect(captured?.fitnessLevel == .intermediate)
    }
}
