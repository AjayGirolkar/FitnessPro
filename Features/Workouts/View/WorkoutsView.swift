//
//  WorkoutsView.swift
//  FitnessPro
//
//  Renders WorkoutsViewModel.state. View holds no business logic — it
//  reacts to state and forwards intents to the ViewModel.
//

import SwiftUI

struct WorkoutsView: View {
    @State var viewModel: WorkoutsViewModel

    var body: some View {
        content
            .navigationTitle("Workouts")
            .task { await viewModel.loadWorkouts() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Loading…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded(let workouts):
            List(workouts) { WorkoutRow(workout: $0) }
                .listStyle(.plain)
                .refreshable { await viewModel.loadWorkouts() }

        case .failed(let message):
            ContentUnavailableView {
                Label("Couldn't load workouts", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Retry") { Task { await viewModel.loadWorkouts() } }
            }
        }
    }
}

private struct WorkoutRow: View {
    let workout: Workout

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name).font(.headline)
                Text(workout.category.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(workout.durationMinutes) min").font(.subheadline)
                Text("\(workout.caloriesBurned) kcal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        WorkoutsView(
            viewModel: WorkoutsViewModel(service: PreviewWorkoutService())
        )
    }
}

/// Inline mock so previews render without networking.
private struct PreviewWorkoutService: WorkoutServiceProtocol {
    func fetchWorkouts() async throws -> [Workout] { Workout.samples }
}
