//
//  PlaylistStore.swift
//  FitnessPro
//
//  Observable persistence for user-saved workout playlists. Backed by the
//  app's KeyValueStore (UserDefaults today); the in-memory array drives the
//  UI and is written back on every mutation.
//

import Foundation
import Observation

@MainActor
@Observable
final class PlaylistStore {
    private(set) var playlists: [WorkoutPlaylist]

    private let store: KeyValueStore
    private static let key = "workouts.playlists"

    init(store: KeyValueStore) {
        self.store = store
        self.playlists = store.value(forKey: Self.key, as: [WorkoutPlaylist].self) ?? []
    }

    /// Newest first.
    func add(_ playlist: WorkoutPlaylist) {
        playlists.insert(playlist, at: 0)
        persist()
    }

    func delete(_ playlist: WorkoutPlaylist) {
        playlists.removeAll { $0.id == playlist.id }
        persist()
    }

    func delete(at offsets: IndexSet) {
        playlists.remove(atOffsets: offsets)
        persist()
    }

    private func persist() {
        store.set(playlists, forKey: Self.key)
    }
}
