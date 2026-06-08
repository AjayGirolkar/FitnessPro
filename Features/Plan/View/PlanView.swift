//
//  PlanView.swift
//  FitnessPro
//
//  Shows the active plan and lets the user regenerate it (re-runs the
//  onboarding → generation flow).
//

import SwiftUI

struct PlanView: View {
    @Environment(AppContainer.self) private var container
    @State private var activeDay: PlanDay?

    var body: some View {
        let plan = container.appState.activePlan
        ZStack {
            AppBackground(showGlow: false)
            ScrollView {
                if let plan {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        TagChip(text: plan.source.badge,
                                tint: plan.source == .ai ? Theme.Colors.secondary : Theme.Colors.accent)
                        Text(plan.name).font(.screenTitle).foregroundStyle(Theme.Colors.textPrimary)
                        Text(plan.rationale).font(.body).foregroundStyle(Theme.Colors.textSecondary)

                        SectionHeader(title: "Your week")
                        ForEach(plan.days) { day in
                            PlanDayCard(day: day) { activeDay = day }
                        }

                        SecondaryButton(title: "Regenerate plan", systemImage: "arrow.triangle.2.circlepath") {
                            container.appState.regeneratePlan()
                        }
                        .padding(.top, Theme.Spacing.sm)
                    }
                    .padding(Theme.Spacing.lg)
                } else {
                    ContentUnavailableView("No plan yet", systemImage: "calendar.badge.plus",
                                           description: Text("Generate a personalized plan to get started."))
                        .padding(.top, Theme.Spacing.xxl)
                }
            }
            .navigationTitle("Plan")
        }
        .fullScreenCover(item: $activeDay) { day in
            WorkoutPlayerView(viewModel: container.makeWorkoutPlayerViewModel(day: day))
        }
    }
}
