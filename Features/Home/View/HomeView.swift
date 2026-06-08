//
//  HomeView.swift
//  FitnessPro
//
//  Dashboard. Greets the user, surfaces today's session from the active
//  plan, and offers quick jumps into the rest of the week.
//

import SwiftUI

struct HomeView: View {
    @Environment(AppContainer.self) private var container
    @State private var activeDay: PlanDay?

    var body: some View {
        let state = container.appState
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    greeting(name: state.user?.name ?? "Athlete", streak: state.streak)

                    if let plan = state.activePlan, let today = plan.days.first {
                        todayCard(plan: plan, today: today)
                        SectionHeader(title: "This week")
                        ForEach(plan.days) { day in
                            PlanDayCard(day: day) { activeDay = day }
                        }
                    } else {
                        emptyState
                    }
                }
                .padding(Theme.Spacing.lg)
            }
        }
        .fullScreenCover(item: $activeDay) { day in
            WorkoutPlayerView(viewModel: container.makeWorkoutPlayerViewModel(day: day))
        }
    }

    private func greeting(name: String, streak: Int) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(salutation)
                    .font(.subheadline).foregroundStyle(Theme.Colors.textSecondary)
                Text(name)
                    .font(.screenTitle).foregroundStyle(Theme.Colors.textPrimary)
            }
            Spacer()
            if streak > 0 {
                Label("\(streak)", systemImage: "flame.fill")
                    .font(.cardTitle)
                    .foregroundStyle(Theme.Colors.warmAccent)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, 6)
                    .background(Theme.Colors.warmAccent.opacity(0.15), in: Capsule())
            }
        }
        .padding(.top, Theme.Spacing.md)
    }

    private func todayCard(plan: WorkoutPlan, today: PlanDay) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                TagChip(text: "TODAY")
                Text(today.focus).font(.sectionTitle).foregroundStyle(Theme.Colors.textPrimary)
                HStack(spacing: Theme.Spacing.lg) {
                    metric("\(today.exercises.count)", "exercises", "list.bullet")
                    metric("~\(today.estimatedMinutes)", "minutes", "clock.fill")
                    metric("\(plan.daysPerWeek)×", "per week", "calendar")
                }
                .padding(.vertical, Theme.Spacing.xs)
                PrimaryButton(title: "Start today's workout", systemImage: "play.fill") {
                    activeDay = today
                }
            }
        }
    }

    private func metric(_ value: String, _ label: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(value, systemImage: icon)
                .font(.cardTitle).foregroundStyle(Theme.Colors.accent)
            Text(label).font(.caption).foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    private var emptyState: some View {
        SurfaceCard {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "sparkles").font(.largeTitle).foregroundStyle(Theme.Colors.accent)
                Text("No active plan yet").font(.cardTitle).foregroundStyle(Theme.Colors.textPrimary)
                Text("Head to the Plan tab to generate one.")
                    .font(.subheadline).foregroundStyle(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
        }
    }

    private var salutation: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }
}
