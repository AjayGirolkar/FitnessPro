//
//  OnboardingView.swift
//  FitnessPro
//
//  HERO flow. Intro offers a personalized questionnaire or a one-tap Quick
//  Start preset. The questionnaire walks the user through the FitnessProfile
//  one focused step at a time.
//

import SwiftUI

struct OnboardingView: View {
    @State var viewModel: OnboardingViewModel
    @State private var phase: Phase = .intro

    enum Phase { case intro, quickStart, quiz }

    var body: some View {
        ZStack {
            AppBackground()
            switch phase {
            case .intro:      intro
            case .quickStart: quickStart
            case .quiz:       quiz
            }
        }
        .animation(.easeInOut, value: phase)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Intro

    private var intro: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            Image(systemName: "wand.and.stars")
                .font(.system(size: 52))
                .foregroundStyle(Theme.Gradients.brand)
            Text("Let's build your plan")
                .font(.screenTitle)
                .foregroundStyle(Theme.Colors.textPrimary)
            Text("Choose how you'd like to start.")
                .font(.body)
                .foregroundStyle(Theme.Colors.textSecondary)

            VStack(spacing: Theme.Spacing.sm) {
                OptionCard(title: "Personalized plan",
                           subtitle: "Answer a few questions — best results",
                           systemImage: "slider.horizontal.3",
                           isSelected: false) { phase = .quiz }
                OptionCard(title: "Quick start",
                           subtitle: "Pick a preset and go",
                           systemImage: "bolt.fill",
                           isSelected: false) { phase = .quickStart }
            }
            .padding(.top, Theme.Spacing.md)
            Spacer()
        }
        .padding(Theme.Spacing.lg)
    }

    // MARK: - Quick start

    private var quickStart: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            backRow { phase = .intro }
            VStack(alignment: .leading, spacing: 4) {
                Text("Quick start").font(.screenTitle).foregroundStyle(Theme.Colors.textPrimary)
                Text("Pick the option that sounds most like you.")
                    .font(.subheadline).foregroundStyle(Theme.Colors.textSecondary)
            }
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(FitnessProfile.QuickStart.allCases) { preset in
                    OptionCard(title: preset.title, subtitle: preset.subtitle,
                               systemImage: preset.systemImage, isSelected: false) {
                        viewModel.finishWithPreset(preset)
                    }
                }
            }
            Spacer()
        }
        .padding(Theme.Spacing.lg)
    }

    // MARK: - Questionnaire

    private var quiz: some View {
        VStack(spacing: Theme.Spacing.md) {
            header
            ScrollView {
                stepContent
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.sm)
            }
            footer
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Button {
                    viewModel.isFirstStep ? (phase = .intro) : viewModel.back()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(Theme.Colors.surface, in: Circle())
                }
                Spacer()
                StepProgressBar(current: viewModel.step.rawValue + 1,
                                total: OnboardingViewModel.Step.allCases.count)
                    .frame(width: 160)
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.step.title)
                    .font(.sectionTitle)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(viewModel.step.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.sm)
    }

    @ViewBuilder
    private var stepContent: some View {
        @Bindable var vm = viewModel
        switch viewModel.step {
        case .goal:
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(Goal.allCases) { goal in
                    OptionCard(title: goal.title, subtitle: goal.subtitle,
                               systemImage: goal.systemImage,
                               isSelected: vm.profile.goal == goal) { vm.profile.goal = goal }
                }
            }
        case .level:
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(FitnessLevel.allCases) { level in
                    OptionCard(title: level.title, subtitle: level.subtitle,
                               systemImage: "figure.strengthtraining.traditional",
                               isSelected: vm.profile.fitnessLevel == level) { vm.profile.fitnessLevel = level }
                }
            }
        case .body:
            bodyStats(vm: $vm)
        case .location:
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(WorkoutLocation.allCases) { loc in
                    OptionCard(title: loc.title, systemImage: loc.systemImage,
                               isSelected: vm.profile.location == loc) { vm.profile.location = loc }
                }
            }
        case .equipment:
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(Equipment.allCases) { item in
                    OptionCard(title: item.title, systemImage: item.systemImage,
                               isSelected: vm.profile.equipment.contains(item)) { vm.toggle(item) }
                }
            }
        case .focus:
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(TargetArea.allCases) { area in
                    OptionCard(title: area.title,
                               isSelected: vm.profile.targetAreas.contains(area)) { vm.toggle(area) }
                }
            }
        case .schedule:
            scheduleStep(vm: $vm)
        case .review:
            reviewStep
        }
    }

    private func bodyStats(vm: Bindable<OnboardingViewModel>) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            SurfaceCard {
                VStack(spacing: Theme.Spacing.md) {
                    HStack {
                        Text("Gender").foregroundStyle(Theme.Colors.textSecondary)
                        Spacer()
                        Picker("Gender", selection: vm.profile.gender) {
                            ForEach(Gender.allCases) { Text($0.title).tag($0) }
                        }
                        .tint(Theme.Colors.accent)
                    }
                    Divider().overlay(Theme.Colors.stroke)
                    Stepper(value: vm.profile.age, in: 12...100) {
                        labeledValue("Age", "\(vm.profile.age.wrappedValue) yrs")
                    }
                }
            }
            sliderCard("Height", value: vm.profile.heightCm, range: 120...220, unit: "cm")
            sliderCard("Weight", value: vm.profile.weightKg, range: 35...180, unit: "kg")
        }
    }

    private func scheduleStep(vm: Bindable<OnboardingViewModel>) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            SurfaceCard {
                VStack(spacing: Theme.Spacing.md) {
                    labeledValue("Days per week", "\(vm.profile.wrappedValue.daysPerWeek)")
                    Slider(value: Binding(
                        get: { Double(vm.profile.wrappedValue.daysPerWeek) },
                        set: { vm.profile.wrappedValue.daysPerWeek = Int($0.rounded()) }
                    ), in: 2...6, step: 1)
                    .tint(Theme.Colors.accent)
                }
            }
            SurfaceCard {
                VStack(spacing: Theme.Spacing.md) {
                    labeledValue("Session length", "\(vm.profile.wrappedValue.sessionMinutes) min")
                    Slider(value: Binding(
                        get: { Double(vm.profile.wrappedValue.sessionMinutes) },
                        set: { vm.profile.wrappedValue.sessionMinutes = Int(($0 / 5).rounded()) * 5 }
                    ), in: 15...75, step: 5)
                    .tint(Theme.Colors.accent)
                }
            }
        }
    }

    private var reviewStep: some View {
        let p = viewModel.profile
        return VStack(spacing: Theme.Spacing.sm) {
            reviewRow("Goal", p.goal.title, "target")
            reviewRow("Level", p.fitnessLevel.title, "chart.bar.fill")
            reviewRow("Location", p.location.title, "mappin.circle.fill")
            reviewRow("Equipment", p.equipment.map(\.title).sorted().joined(separator: ", "), "dumbbell.fill")
            reviewRow("Focus", p.targetAreas.map(\.title).sorted().joined(separator: ", "), "scope")
            reviewRow("Schedule", "\(p.daysPerWeek)×/week · \(p.sessionMinutes) min", "calendar")
        }
    }

    // MARK: - Footer

    private var footer: some View {
        PrimaryButton(
            title: viewModel.isLastStep ? "Generate my plan" : "Continue",
            systemImage: viewModel.isLastStep ? "sparkles" : "arrow.right",
            isEnabled: viewModel.canAdvance
        ) {
            viewModel.next()
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.sm)
    }

    // MARK: - Small builders

    private func backRow(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.headline)
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(width: 40, height: 40)
                .background(Theme.Colors.surface, in: Circle())
        }
    }

    private func labeledValue(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Theme.Colors.textSecondary)
            Spacer()
            Text(value).font(.cardTitle).foregroundStyle(Theme.Colors.textPrimary)
        }
    }

    private func sliderCard(_ label: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String) -> some View {
        SurfaceCard {
            VStack(spacing: Theme.Spacing.md) {
                labeledValue(label, "\(Int(value.wrappedValue)) \(unit)")
                Slider(value: value, in: range, step: 1).tint(Theme.Colors.accent)
            }
        }
    }

    private func reviewRow(_ label: String, _ value: String, _ icon: String) -> some View {
        SurfaceCard {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .foregroundStyle(Theme.Colors.accent)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).font(.caption).foregroundStyle(Theme.Colors.textSecondary)
                    Text(value.isEmpty ? "—" : value)
                        .font(.cardTitle).foregroundStyle(Theme.Colors.textPrimary)
                }
                Spacer()
            }
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingView(viewModel: OnboardingViewModel())
    }
    .preferredColorScheme(.dark)
}
