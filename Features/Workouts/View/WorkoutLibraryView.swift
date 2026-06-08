//
//  WorkoutLibraryView.swift
//  FitnessPro
//
//  Two-step workout browser: pick intensity (level) → pick type (focus) →
//  see a runnable list of exercises → start a guided session (whole list or a
//  hand-picked selection) in the WorkoutPlayer. Search spans the whole catalog.
//

import SwiftUI

struct WorkoutLibraryView: View {
    @State var viewModel: WorkoutLibraryViewModel
    @Environment(AppContainer.self) private var container
    @State private var sessionDay: PlanDay?

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
                        VStack(spacing: Theme.Spacing.lg) {
                            if !viewModel.playlists.isEmpty { playlistsSection }
                            levelGrid
                        }
                        .padding(.vertical, Theme.Spacing.md)
                    }
                }
            }
            .navigationTitle("Workouts")
            .navigationDestination(for: Exercise.Level.self) { level in
                FocusGridView(level: level, viewModel: viewModel)
            }
            .navigationDestination(for: BrowseSelection.self) { selection in
                SessionListView(selection: selection,
                                exercises: viewModel.exercises(in: selection),
                                viewModel: viewModel)
            }
            .navigationDestination(for: Exercise.self) { ExerciseDetailView(exercise: $0) }
            .fullScreenCover(item: $sessionDay) { day in
                WorkoutPlayerView(viewModel: container.makeWorkoutPlayerViewModel(day: day))
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search 800+ exercises")
    }

    // MARK: - Saved playlists

    private var playlistsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Your Playlists")
                .font(.sectionTitle).foregroundStyle(Theme.Colors.textPrimary)
                .padding(.horizontal, Theme.Spacing.md)

            VStack(spacing: Theme.Spacing.xs) {
                ForEach(viewModel.playlists) { playlist in
                    PlaylistRow(
                        playlist: playlist,
                        onPlay: { sessionDay = viewModel.planDay(for: playlist) },
                        onDelete: { viewModel.deletePlaylist(playlist) }
                    )
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    // MARK: - Step 1: intensity

    private var levelGrid: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Choose your intensity")
                .font(.subheadline).foregroundStyle(Theme.Colors.textSecondary)
                .padding(.horizontal, Theme.Spacing.md)

            LazyVGrid(columns: columns, spacing: Theme.Spacing.sm) {
                ForEach(viewModel.levels, id: \.self) { level in
                    NavigationLink(value: level) {
                        BrowseTile(title: level.displayName,
                                   subtitle: level.browseSubtitle,
                                   count: viewModel.count(level: level),
                                   systemImage: level.systemImage,
                                   tint: level.tint)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    // MARK: - Search

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

// MARK: - Step 2: type (focus)

struct FocusGridView: View {
    let level: Exercise.Level
    let viewModel: WorkoutLibraryViewModel

    private let columns = [GridItem(.flexible(), spacing: Theme.Spacing.sm),
                           GridItem(.flexible(), spacing: Theme.Spacing.sm)]

    var body: some View {
        ZStack {
            AppBackground(showGlow: false)
            ScrollView {
                LazyVGrid(columns: columns, spacing: Theme.Spacing.sm) {
                    ForEach(viewModel.focuses) { focus in
                        NavigationLink(value: BrowseSelection(level: level, focus: focus)) {
                            BrowseTile(title: focus.title,
                                       subtitle: focus.subtitle,
                                       count: viewModel.count(level: level, focus: focus),
                                       systemImage: focus.systemImage,
                                       tint: focus.tint)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.count(level: level, focus: focus) == 0)
                        .opacity(viewModel.count(level: level, focus: focus) == 0 ? 0.4 : 1)
                    }
                }
                .padding(Theme.Spacing.md)
            }
        }
        .navigationTitle(level.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Step 3: exercise list + start session

struct SessionListView: View {
    let selection: BrowseSelection
    let exercises: [Exercise]
    let viewModel: WorkoutLibraryViewModel

    @Environment(AppContainer.self) private var container
    @State private var selectedIDs: Set<String> = []
    @State private var sessionDay: PlanDay?
    @State private var showSaveAlert = false
    @State private var playlistName = ""

    private let builder = SessionBuilder()

    private var allSelected: Bool { !exercises.isEmpty && selectedIDs.count == exercises.count }

    private var selectedExercises: [Exercise] {
        exercises.filter { selectedIDs.contains($0.id) }
    }

    var body: some View {
        ZStack {
            AppBackground(showGlow: false)
            if exercises.isEmpty {
                ContentUnavailableView("No exercises",
                                       systemImage: "dumbbell",
                                       description: Text("Nothing matches this combination yet."))
            } else {
                list
            }
        }
        .navigationTitle(selection.focus.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !exercises.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(allSelected ? "Clear" : "Select all") {
                        selectedIDs = allSelected ? [] : Set(exercises.map(\.id))
                    }
                    .tint(Theme.Colors.accent)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !exercises.isEmpty { startBar }
        }
        .fullScreenCover(item: $sessionDay) { day in
            WorkoutPlayerView(viewModel: container.makeWorkoutPlayerViewModel(day: day))
        }
        .alert("Save playlist", isPresented: $showSaveAlert) {
            TextField("Playlist name", text: $playlistName)
            Button("Save") {
                viewModel.savePlaylist(name: playlistName,
                                       level: selection.level,
                                       exercises: selectedExercises)
                selectedIDs = []
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Save \(selectedIDs.count) selected exercise\(selectedIDs.count == 1 ? "" : "s") to replay anytime.")
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.xs) {
                Text("\(selection.level.displayName) intensity · \(exercises.count) exercises")
                    .font(.caption).foregroundStyle(Theme.Colors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, Theme.Spacing.xs)

                ForEach(exercises) { exercise in
                    SelectableExerciseRow(
                        exercise: exercise,
                        isSelected: selectedIDs.contains(exercise.id),
                        onToggle: { toggle(exercise) }
                    )
                }
            }
            .padding(Theme.Spacing.md)
        }
    }

    private var startBar: some View {
        VStack(spacing: Theme.Spacing.sm) {
            if !selectedIDs.isEmpty {
                HStack(spacing: Theme.Spacing.sm) {
                    SecondaryButton(title: "Save", systemImage: "bookmark") {
                        playlistName = selection.title
                        showSaveAlert = true
                    }
                    PrimaryButton(title: "Start \(selectedIDs.count)", systemImage: "play.fill") {
                        startSession()
                    }
                }
            } else {
                PrimaryButton(title: "Start session · \(exercises.count)", systemImage: "play.fill") {
                    startSession()
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(.ultraThinMaterial)
    }

    private func toggle(_ exercise: Exercise) {
        if selectedIDs.contains(exercise.id) { selectedIDs.remove(exercise.id) }
        else { selectedIDs.insert(exercise.id) }
    }

    private func startSession() {
        let chosen = selectedIDs.isEmpty ? exercises : selectedExercises
        sessionDay = builder.makeDay(focus: selection.focus.title,
                                     exercises: chosen,
                                     level: selection.level)
    }
}

// MARK: - Playlist row

struct PlaylistRow: View {
    let playlist: WorkoutPlaylist
    let onPlay: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "music.note.list")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.Colors.accent)
                .frame(width: 44, height: 44)
                .background(Theme.Colors.accentSoft, in: RoundedRectangle(cornerRadius: Theme.Radius.sm))
            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.name).font(.cardTitle).foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(1)
                Text(playlist.subtitle).font(.caption).foregroundStyle(Theme.Colors.textSecondary)
            }
            Spacer()
            Button(action: onPlay) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Theme.Colors.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.md))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.Colors.stroke, lineWidth: 1))
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Tiles & rows

/// Square category/level tile used in both browse steps.
struct BrowseTile: View {
    let title: String
    let subtitle: String
    let count: Int
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 48, height: 48)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: Theme.Radius.sm))
            Spacer(minLength: Theme.Spacing.sm)
            Text(title).font(.cardTitle).foregroundStyle(Theme.Colors.textPrimary)
            Text(subtitle).font(.caption).foregroundStyle(Theme.Colors.textSecondary)
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

/// Exercise row with a leading select toggle (taps the toggle to add/remove
/// from the custom session; taps the body to open detail).
struct SelectableExerciseRow: View {
    let exercise: Exercise
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? Theme.Colors.accent : Theme.Colors.textTertiary)
            }
            .buttonStyle(.plain)

            NavigationLink(value: exercise) { ExerciseRow(exercise: exercise) }
                .buttonStyle(.plain)
        }
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
            TagChip(text: exercise.level.displayName, tint: exercise.level.tint)
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.md))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.Colors.stroke, lineWidth: 1))
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
    let container = AppContainer()
    return WorkoutLibraryView(viewModel: container.makeWorkoutLibraryViewModel())
        .environment(container)
        .preferredColorScheme(.dark)
}
