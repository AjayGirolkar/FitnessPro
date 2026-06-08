//
//  WorkoutPlayerView.swift
//  FitnessPro
//
//  Full-screen active-session runner. Three phases: exercise (set tracker +
//  rep/weight log or timed countdown), rest (countdown ring + up-next), and
//  finished (summary). Presented as a fullScreenCover from Home / Plan.
//

import SwiftUI

struct WorkoutPlayerView: View {
    @State var viewModel: WorkoutPlayerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showQuitConfirm = false

    var body: some View {
        ZStack {
            AppBackground(showGlow: false)

            VStack(spacing: 0) {
                topBar
                Group {
                    switch viewModel.phase {
                    case .exercise: exercisePhase
                    case .resting:  restPhase
                    case .finished: finishedPhase
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .padding(Theme.Spacing.lg)
        }
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
        .interactiveDismissDisabled(viewModel.phase != .finished)
        .confirmationDialog("End workout?", isPresented: $showQuitConfirm, titleVisibility: .visible) {
            Button("End workout", role: .destructive) {
                viewModel.endEarly()
                dismiss()
            }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("Sets you've completed will still be logged.")
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack {
                Button {
                    if viewModel.phase == .finished { dismiss() } else { showQuitConfirm = true }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(Theme.Colors.surface, in: Circle())
                }
                Spacer()
                Text(viewModel.day.focus)
                    .font(.cardTitle).foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
                Text(timeString(viewModel.elapsedSeconds))
                    .font(.cardTitle.monospacedDigit())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(width: 64, alignment: .trailing)
            }
            StepProgressBar(current: viewModel.completedSets, total: viewModel.totalSets)
        }
    }

    // MARK: - Exercise phase

    private var exercisePhase: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ExercisePlayerImage(url: viewModel.imageURL)

            VStack(spacing: Theme.Spacing.xs) {
                Text(viewModel.currentPlanned.name)
                    .font(.sectionTitle).foregroundStyle(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Set \(viewModel.setNumber) of \(viewModel.setCount)")
                    .font(.subheadline).foregroundStyle(Theme.Colors.accent)
            }

            if viewModel.currentPlanned.isTimed {
                timedControls
            } else {
                repWeightControls
            }

            Spacer()

            PrimaryButton(title: "Complete set", systemImage: "checkmark") {
                viewModel.completeSet()
            }
        }
    }

    private var repWeightControls: some View {
        HStack(spacing: Theme.Spacing.md) {
            Stepper2(
                title: "Reps",
                value: "\(viewModel.currentSet.reps)",
                onMinus: { viewModel.adjustReps(-1) },
                onPlus: { viewModel.adjustReps(1) }
            )
            Stepper2(
                title: "Weight (kg)",
                value: viewModel.currentSet.weight == 0 ? "BW" : weightString(viewModel.currentSet.weight),
                onMinus: { viewModel.adjustWeight(-2.5) },
                onPlus: { viewModel.adjustWeight(2.5) }
            )
        }
    }

    private var timedControls: some View {
        VStack(spacing: Theme.Spacing.md) {
            Text(timeString(viewModel.isTimedRunning ? viewModel.timedRemaining
                                                       : viewModel.currentPlanned.durationSeconds))
                .font(.system(size: 64, weight: .heavy, design: .rounded).monospacedDigit())
                .foregroundStyle(Theme.Colors.textPrimary)
            if !viewModel.isTimedRunning {
                SecondaryButton(title: "Start timer", systemImage: "timer") {
                    viewModel.startTimedSet()
                }
            } else {
                Text("Hold the position…")
                    .font(.subheadline).foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }

    // MARK: - Rest phase

    private var restPhase: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            Text("REST").font(.pill).foregroundStyle(Theme.Colors.secondary)
                .tracking(2)

            ZStack {
                ProgressRing(progress: viewModel.restProgress, lineWidth: 12, tint: Theme.Colors.secondary)
                    .frame(width: 200, height: 200)
                Text(timeString(restRemaining))
                    .font(.system(size: 56, weight: .heavy, design: .rounded).monospacedDigit())
                    .foregroundStyle(Theme.Colors.textPrimary)
            }

            if let next = viewModel.upNext {
                VStack(spacing: 2) {
                    Text(viewModel.upNextIsNewExercise ? "Up next" : "Next set")
                        .font(.caption).foregroundStyle(Theme.Colors.textTertiary)
                    Text(next.name).font(.cardTitle).foregroundStyle(Theme.Colors.textPrimary)
                    Text(next.prescription).font(.subheadline).foregroundStyle(Theme.Colors.textSecondary)
                }
            }

            Spacer()

            HStack(spacing: Theme.Spacing.md) {
                SecondaryButton(title: "+15s", systemImage: "goforward.15") { viewModel.addRest(15) }
                PrimaryButton(title: "Skip rest", systemImage: "forward.fill") { viewModel.skipRest() }
            }
        }
    }

    private var restRemaining: Int {
        if case .resting(let r) = viewModel.phase { return r }
        return 0
    }

    // MARK: - Finished phase

    private var finishedPhase: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(Theme.Colors.accent)
            Text("Workout complete!")
                .font(.screenTitle).foregroundStyle(Theme.Colors.textPrimary)
            Text(viewModel.day.focus)
                .font(.cardTitle).foregroundStyle(Theme.Colors.textSecondary)

            HStack(spacing: Theme.Spacing.md) {
                summaryStat("\(viewModel.completedSets)", "sets", "checklist")
                summaryStat(timeString(viewModel.elapsedSeconds), "time", "clock.fill")
                summaryStat(volumeString, "volume", "scalemass.fill")
            }
            .padding(.top, Theme.Spacing.sm)

            Spacer()
            PrimaryButton(title: "Done", systemImage: "house.fill") { dismiss() }
        }
    }

    private func summaryStat(_ value: String, _ label: String, _ icon: String) -> some View {
        SurfaceCard {
            VStack(spacing: 4) {
                Image(systemName: icon).foregroundStyle(Theme.Colors.accent)
                Text(value).font(.cardTitle.monospacedDigit()).foregroundStyle(Theme.Colors.textPrimary)
                Text(label).font(.caption).foregroundStyle(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Formatting

    private var volumeString: String {
        let v = viewModel.totalVolume
        return v == 0 ? "—" : "\(Int(v)) kg"
    }

    private func weightString(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : String(format: "%.1f", w)
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - Subviews

/// Large hero image for the active exercise with graceful fallback.
private struct ExercisePlayerImage: View {
    let url: URL?

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image): image.resizable().scaledToFill()
            case .empty: ZStack { placeholder; ProgressView().tint(Theme.Colors.textTertiary) }
            default: placeholder
            }
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg).stroke(Theme.Colors.stroke, lineWidth: 1))
    }

    private var placeholder: some View {
        Image(systemName: "figure.strengthtraining.traditional")
            .font(.system(size: 48)).foregroundStyle(Theme.Colors.textTertiary)
    }
}

/// Minus / value / plus control used for reps & weight.
private struct Stepper2: View {
    let title: String
    let value: String
    let onMinus: () -> Void
    let onPlus: () -> Void

    var body: some View {
        SurfaceCard {
            VStack(spacing: Theme.Spacing.sm) {
                Text(title).font(.caption).foregroundStyle(Theme.Colors.textSecondary)
                HStack {
                    stepButton("minus", action: onMinus)
                    Spacer()
                    Text(value)
                        .font(.metric.monospacedDigit())
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .frame(minWidth: 56)
                    Spacer()
                    stepButton("plus", action: onPlus)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func stepButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.Colors.accent)
                .frame(width: 40, height: 40)
                .background(Theme.Colors.accentSoft, in: Circle())
        }
    }
}

#Preview {
    WorkoutPlayerView(
        viewModel: WorkoutPlayerViewModel(
            day: WorkoutPlan.preview.days[0],
            provider: ExerciseRepository(seed: [])
        )
    )
    .preferredColorScheme(.dark)
}
