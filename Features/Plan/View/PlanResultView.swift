//
//  PlanResultView.swift
//  FitnessPro
//
//  Shows the generated plan. While generating, an animated state keeps the
//  HERO moment feeling alive. Loaded state lists the weekly schedule with
//  expandable days; failed state offers a retry.
//

import SwiftUI

struct PlanResultView: View {
    @State var viewModel: PlanResultViewModel

    var body: some View {
        ZStack {
            AppBackground()
            switch viewModel.state {
            case .generating:        GeneratingView()
            case .loaded(let plan):  loaded(plan)
            case .failed(let msg):   failed(msg)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.generate() }
    }

    // MARK: - Loaded

    private func loaded(_ plan: WorkoutPlan) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        TagChip(text: plan.source.badge,
                                tint: plan.source == .ai ? Theme.Colors.secondary : Theme.Colors.accent)
                        Text(plan.name)
                            .font(.screenTitle)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text(plan.rationale)
                            .font(.body)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    .padding(.top, Theme.Spacing.xl)

                    statsRow(plan)

                    SectionHeader(title: "Your week")
                    ForEach(plan.days) { day in
                        PlanDayCard(day: day)
                    }
                }
                .padding(Theme.Spacing.lg)
            }
            PrimaryButton(title: "Start this plan", systemImage: "play.fill") {
                viewModel.start()
            }
            .padding(Theme.Spacing.lg)
        }
    }

    private func statsRow(_ plan: WorkoutPlan) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            statTile("\(plan.daysPerWeek)", "days/week", "calendar")
            statTile("\(plan.sessionMinutes)", "minutes", "clock.fill")
            statTile("\(plan.totalExercises)", "exercises", "list.bullet")
        }
    }

    private func statTile(_ value: String, _ label: String, _ icon: String) -> some View {
        SurfaceCard(padding: Theme.Spacing.sm) {
            VStack(spacing: 4) {
                Image(systemName: icon).foregroundStyle(Theme.Colors.accent)
                Text(value).font(.metric).foregroundStyle(Theme.Colors.textPrimary)
                Text(label).font(.caption).foregroundStyle(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Failed

    private func failed(_ message: String) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44)).foregroundStyle(Theme.Colors.warning)
            Text("Couldn't build your plan").font(.sectionTitle).foregroundStyle(Theme.Colors.textPrimary)
            Text(message).font(.subheadline).foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            PrimaryButton(title: "Try again", systemImage: "arrow.clockwise") {
                Task { await viewModel.generate() }
            }
            .padding(.top, Theme.Spacing.sm)
        }
        .padding(Theme.Spacing.xl)
    }
}

// MARK: - Generating animation

private struct GeneratingView: View {
    @State private var pulse = false
    @State private var messageIndex = 0

    private let messages = [
        "Analyzing your profile…",
        "Selecting the best exercises…",
        "Balancing your week…",
        "Dialing in sets & reps…",
        "Almost there…"
    ]
    private let timer = Timer.publish(every: 1.6, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.accentSoft)
                    .frame(width: 140, height: 140)
                    .scaleEffect(pulse ? 1.12 : 0.92)
                Image(systemName: "sparkles")
                    .font(.system(size: 54))
                    .foregroundStyle(Theme.Gradients.brand)
            }
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)

            Text("Building your plan")
                .font(.sectionTitle)
                .foregroundStyle(Theme.Colors.textPrimary)
            Text(messages[messageIndex])
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.textSecondary)
                .transition(.opacity)
                .id(messageIndex)
        }
        .onAppear { pulse = true }
        .onReceive(timer) { _ in
            withAnimation { messageIndex = (messageIndex + 1) % messages.count }
        }
    }
}

// MARK: - Reusable day card

struct PlanDayCard: View {
    let day: PlanDay
    var onStart: (() -> Void)? = nil
    @State private var expanded = false

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Button { withAnimation(.easeInOut) { expanded.toggle() } } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(day.dayLabel).font(.caption).foregroundStyle(Theme.Colors.accent)
                            Text(day.focus).font(.cardTitle).foregroundStyle(Theme.Colors.textPrimary)
                            Text("\(day.exercises.count) exercises · ~\(day.estimatedMinutes) min")
                                .font(.subheadline).foregroundStyle(Theme.Colors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }
                .buttonStyle(.plain)

                if expanded {
                    Divider().overlay(Theme.Colors.stroke)
                    ForEach(day.exercises) { ex in
                        HStack {
                            Image(systemName: "circle.fill").font(.system(size: 5))
                                .foregroundStyle(Theme.Colors.accent)
                            Text(ex.name).font(.subheadline).foregroundStyle(Theme.Colors.textPrimary)
                            Spacer()
                            Text(ex.prescription).font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                    if let onStart {
                        PrimaryButton(title: "Start workout", systemImage: "play.fill", action: onStart)
                            .padding(.top, Theme.Spacing.xs)
                    }
                }
            }
        }
    }
}

#Preview("Loaded") {
    PlanDayCard(day: WorkoutPlan.preview.days[0])
        .padding()
        .background(Theme.Colors.background)
        .preferredColorScheme(.dark)
}
