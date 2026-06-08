//
//  WorkoutLibraryViewModel.swift
//  FitnessPro
//
//  Backs the exercise browser: category tiles plus search across the whole
//  bundled catalog. Pure querying over ExerciseProviding.
//

import Foundation
import Observation

@MainActor
@Observable
final class WorkoutLibraryViewModel {
    /// Intensity axis (browse step 1) and type axis (browse step 2).
    let levels = Exercise.Level.allCases
    let focuses = WorkoutFocus.allCases
    var searchText = ""

    /// Cap a single session list so it stays runnable (user can multi-select).
    static let maxSessionExercises = 30

    private let provider: ExerciseProviding
    private let playlistStore: PlaylistStore
    private let builder = SessionBuilder()

    init(provider: ExerciseProviding, playlistStore: PlaylistStore) {
        self.provider = provider
        self.playlistStore = playlistStore
    }

    // MARK: - Two-step browse (level → focus → list)

    /// Exercises matching `focus`, at or below `level`, compound moves first,
    /// capped to a runnable session size.
    func exercises(level: Exercise.Level, focus: WorkoutFocus) -> [Exercise] {
        provider.all()
            .filter { focus.matches($0) && $0.level.rank <= level.rank }
            .sorted { a, b in
                let ac = a.mechanic == "compound", bc = b.mechanic == "compound"
                if ac != bc { return ac }
                return a.name < b.name
            }
            .prefix(Self.maxSessionExercises)
            .map { $0 }
    }

    func exercises(in selection: BrowseSelection) -> [Exercise] {
        exercises(level: selection.level, focus: selection.focus)
    }

    /// Count of matching exercises for a (level, focus) tile.
    func count(level: Exercise.Level, focus: WorkoutFocus) -> Int {
        provider.all().filter { focus.matches($0) && $0.level.rank <= level.rank }.count
    }

    /// Total exercises available at a given intensity (across all focuses).
    func count(level: Exercise.Level) -> Int {
        provider.all().filter { $0.level.rank <= level.rank }.count
    }

    // MARK: - Custom playlists

    var playlists: [WorkoutPlaylist] { playlistStore.playlists }

    /// Persist a hand-picked set as a replayable playlist.
    func savePlaylist(name: String, level: Exercise.Level, exercises: [Exercise]) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmed.isEmpty ? "My Playlist" : trimmed
        playlistStore.add(WorkoutPlaylist(name: finalName,
                                          level: level,
                                          exerciseIDs: exercises.map(\.id)))
    }

    func deletePlaylist(_ playlist: WorkoutPlaylist) {
        playlistStore.delete(playlist)
    }

    /// Resolve a saved playlist into a runnable day (nil if none of its
    /// exercises still exist in the catalog).
    func planDay(for playlist: WorkoutPlaylist) -> PlanDay? {
        let resolved = playlist.exerciseIDs.compactMap { provider.exercise(id: $0) }
        return builder.makeDay(focus: playlist.name, exercises: resolved, level: playlist.level)
    }

    // MARK: - Legacy flat-category queries (kept for repo/tests compatibility)

    func exercises(in category: WorkoutCategory) -> [Exercise] {
        provider.exercises(in: category).sorted { $0.name < $1.name }
    }

    func count(in category: WorkoutCategory) -> Int {
        provider.exercises(in: category).count
    }

    var searchResults: [Exercise] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return [] }
        return provider.all()
            .filter { $0.name.lowercased().contains(query)
                   || $0.primaryMuscles.contains { $0.lowercased().contains(query) } }
            .sorted { $0.name < $1.name }
    }

    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
