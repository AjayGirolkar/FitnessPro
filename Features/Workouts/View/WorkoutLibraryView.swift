//
//  WorkoutLibraryView.swift
//  FitnessPro
//
//  Browse exercises by category or search the whole catalog. Streams
//  exercise images on demand from the public dataset.
//

import SwiftUI

struct WorkoutLibraryView: View {
    @State var viewModel: WorkoutLibraryViewModel

    private let columns = [GridItem(.flexible(), spacing: Theme.Spacing.sm),
                           GridItem(.flexible(), spacing: Theme.Spacing.sm)]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground(showGlow: false)
                ScrollView {
                    if viewModel.isSearching {
                        searchResults
                    } else {
                        categoryGrid
                    }
                }
            }
            .navigationTitle("Workouts")
            .navigationDestination(for: WorkoutCategory.self) { category in
                ExerciseListView(category: category, exercises: viewModel.exercises(in: category))
            }
            .navigationDestination(for: Exercise.self) { ExerciseDetailView(exercise: $0) }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search 800+ exercises")
    }

    private var categoryGrid: some View {
        LazyVGrid(columns: columns, spacing: Theme.Spacing.sm) {
            ForEach(viewModel.categories) { category in
                NavigationLink(value: category) {
                    CategoryTile(category: category, count: viewModel.count(in: category))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Theme.Spacing.md)
    }

    private var searchResults: some View {
        LazyVStack(spacing: Theme.Spacing.xs) {
            ForEach(viewModel.searchResults) { exercise in
                NavigationLink(value: exercise) { ExerciseRow(exercise: exercise) }
                    .buttonStyle(.plain)
            }
        }
        .padding(Theme.Spacing.md)
    }
}

// MARK: - Category tile

struct CategoryTile: View {
    let category: WorkoutCategory
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Image(systemName: category.systemImage)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(category.tint)
                .frame(width: 48, height: 48)
                .background(category.tint.opacity(0.15), in: RoundedRectangle(cornerRadius: Theme.Radius.sm))
            Spacer(minLength: Theme.Spacing.sm)
            Text(category.title).font(.cardTitle).foregroundStyle(Theme.Colors.textPrimary)
            Text(category.subtitle).font(.caption).foregroundStyle(Theme.Colors.textSecondary)
                .lineLimit(1)
            Text("\(count) exercises").font(.caption2).foregroundStyle(Theme.Colors.textTertiary)
        }
        .padding(Theme.Spacing.md)
        .frame(height: 170, alignment: .topLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.md))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.Colors.stroke, lineWidth: 1))
    }
}

// MARK: - List + row

struct ExerciseListView: View {
    let category: WorkoutCategory
    let exercises: [Exercise]

    var body: some View {
        ZStack {
            AppBackground(showGlow: false)
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.xs) {
                    ForEach(exercises) { exercise in
                        NavigationLink(value: exercise) { ExerciseRow(exercise: exercise) }
                            .buttonStyle(.plain)
                    }
                }
                .padding(Theme.Spacing.md)
            }
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ExerciseThumbnail(url: exercise.imageURLs.first, size: 56)
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name).font(.cardTitle).foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(1)
                Text("\(exercise.primaryMuscle) · \(exercise.equipmentDisplay)")
                    .font(.subheadline).foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            TagChip(text: exercise.level.displayName,
                    tint: level(exercise.level))
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.md))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.Colors.stroke, lineWidth: 1))
    }

    private func level(_ l: Exercise.Level) -> Color {
        switch l {
        case .beginner:     return Theme.Colors.accent
        case .intermediate: return Theme.Colors.secondary
        case .advanced:     return Color(hex: 0x9B5CFF)
        }
    }
}

/// Square remote image with graceful placeholder.
struct ExerciseThumbnail: View {
    let url: URL?
    var size: CGFloat = 56

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                placeholder
            case .empty:
                ZStack { placeholder; ProgressView().tint(Theme.Colors.textTertiary) }
            @unknown default:
                placeholder
            }
        }
        .frame(width: size, height: size)
        .background(Theme.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
    }

    private var placeholder: some View {
        Image(systemName: "figure.strengthtraining.traditional")
            .foregroundStyle(Theme.Colors.textTertiary)
    }
}

#Preview {
    WorkoutLibraryView(viewModel: WorkoutLibraryViewModel(provider: ExerciseRepository(seed: [.preview])))
        .preferredColorScheme(.dark)
}
