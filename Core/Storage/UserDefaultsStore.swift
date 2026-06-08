//
//  UserDefaultsStore.swift
//  FitnessPro
//
//  Lightweight typed wrapper over UserDefaults for small preferences.
//  For secrets/tokens use Keychain instead (add a KeychainStore later).
//

import Foundation

protocol KeyValueStore: Sendable {
    func value<T: Codable>(forKey key: String, as type: T.Type) -> T?
    func set<T: Codable>(_ value: T, forKey key: String)
    func remove(forKey key: String)
}

struct UserDefaultsStore: KeyValueStore {
    // UserDefaults is thread-safe but not Sendable-annotated by the SDK.
    nonisolated(unsafe) private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func value<T: Codable>(forKey key: String, as type: T.Type) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func set<T: Codable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
