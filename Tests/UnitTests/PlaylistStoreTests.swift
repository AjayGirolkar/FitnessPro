//
//  PlaylistStoreTests.swift
//  FitnessProTests
//
//  Save / delete / persistence behaviour of the playlist store, backed by an
//  in-memory KeyValueStore so the tests stay hermetic.
//

import Testing
import Foundation
@testable import FitnessPro

/// In-memory KeyValueStore for hermetic tests (no UserDefaults side effects).
private final class MemoryStore: KeyValueStore, @unchecked Sendable {
    private var storage: [String: Data] = [:]

    func value<T: Codable>(forKey key: String, as type: T.Type) -> T? {
        guard let data = storage[key] else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    func set<T: Codable>(_ value: T, forKey key: String) {
        storage[key] = try? JSONEncoder().encode(value)
    }
    func remove(forKey key: String) { storage[key] = nil }
}

@MainActor
@Suite("PlaylistStore")
struct PlaylistStoreTests {

    @Test func startsEmpty() {
        #expect(PlaylistStore(store: MemoryStore()).playlists.isEmpty)
    }

    @Test func addInsertsNewestFirst() {
        let store = PlaylistStore(store: MemoryStore())
        store.add(WorkoutPlaylist(name: "A", level: .beginner, exerciseIDs: ["x"]))
        store.add(WorkoutPlaylist(name: "B", level: .advanced, exerciseIDs: ["y", "z"]))
        #expect(store.playlists.map(\.name) == ["B", "A"])
        #expect(store.playlists.first?.exerciseCount == 2)
    }

    @Test func deleteRemovesByID() {
        let store = PlaylistStore(store: MemoryStore())
        let p = WorkoutPlaylist(name: "A", level: .beginner, exerciseIDs: ["x"])
        store.add(p)
        store.delete(p)
        #expect(store.playlists.isEmpty)
    }

    @Test func persistsAcrossInstances() {
        let backing = MemoryStore()
        let first = PlaylistStore(store: backing)
        first.add(WorkoutPlaylist(name: "Saved", level: .intermediate, exerciseIDs: ["a", "b"]))

        let second = PlaylistStore(store: backing)
        #expect(second.playlists.count == 1)
        #expect(second.playlists.first?.name == "Saved")
        #expect(second.playlists.first?.level == .intermediate)
        #expect(second.playlists.first?.exerciseIDs == ["a", "b"])
    }
}
