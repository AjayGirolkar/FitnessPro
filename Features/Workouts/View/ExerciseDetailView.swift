//
//  ExerciseDetailView.swift
//  FitnessPro
//
//  Full exercise detail: image carousel, metadata, step-by-step
//  instructions, and a lightweight set/rep/rest customizer.
//

import SwiftUI

struct ExerciseDetailView: View {
    let exercise: Exercise

    // Local customization (persisting per-exercise is a future enhancement).
    @State private var sets = 3
    @State private var reps = 12
    @State private var restSeconds = 45

    var body: some View {
        ZStack {
            AppBackground(showGlow: false)
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    carousel
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        title
                        chips
                        customizer
                        instructions
                        if !exercise.secondaryMuscles.isEmpty { secondary }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                }
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var carousel: some View {
        TabView {
            ForEach(Array(exercise.imageURLs.enumerated()), id: \.offset) { _, url in
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFit()
                    case .empty: ProgressView().tint(Theme.Colors.textTertiary)
                    default:
                        Image(systemName: "photo")
                            .font(.largeTitle).foregroundStyle(Theme.Colors.textTertiary)
                    }
                }
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .frame(height: 280)
        .background(Theme.Colors.surface)
    }

    private var title: some View {
        Text(exercise.name)
            .font(.screenTitle)
            .foregroundStyle(Theme.Colors.textPrimary)
    }

    private var chips: some View {
        HStack(spacing: Theme.Spacing.xs) {
            TagChip(text: exercise.level.displayName)
            TagChip(text: exercise.primaryMuscle, tint: Theme.Colors.secondary)
            TagChip(text: exercise.equipmentDisplay, tint: Theme.Colors.warmAccent)
        }
    }

    private var customizer: some View {
        SurfaceCard {
            VStack(spacing: Theme.Spacing.sm) {
                HStack {
                    Text("Customize").font(.cardTitle).foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    Text("\(sets) × \(reps) · \(restSeconds)s rest")
                        .font(.subheadline).foregroundStyle(Theme.Colors.accent)
                }
                Stepper("Sets: \(sets)", value: $sets, in: 1...8)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Stepper("Reps: \(reps)", value: $reps, in: 1...30)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Stepper("Rest: \(restSeconds)s", value: $restSeconds, in: 0...180, step: 15)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .tint(Theme.Colors.accent)
    }

    private var instructions: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "How to do it")
            ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.black)
                        .frame(width: 24, height: 24)
                        .background(Theme.Colors.accent, in: Circle())
                    Text(step)
                        .font(.body)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
    }

    private var secondary: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "Also works")
            FlowChips(items: exercise.secondaryMuscles.map { $0.capitalized })
        }
    }
}

/// Simple wrapping chip row.
struct FlowChips: View {
    let items: [String]
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: Theme.Spacing.xs)],
                  alignment: .leading, spacing: Theme.Spacing.xs) {
            ForEach(items, id: \.self) { TagChip(text: $0, tint: Theme.Colors.secondary) }
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(exercise: .preview)
    }
    .preferredColorScheme(.dark)
}
