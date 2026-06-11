//
//  WidgetSnapshot.swift
//  FitnessPro
//
//  Lightweight state the main app publishes to the shared App Group so the
//  home-screen widget can render without launching the app. Written by
//  AppState, read by the widget timeline provider.
//

import Foundation

enum AppGroup {
    static let identifier = "group.com.ajaygirolkar.fitnesspro"
    static let snapshotKey = "widget.snapshot"

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }
}

/// Snapshot of training state surfaced on the widget.
struct WidgetSnapshot: Codable, Equatable {
    var streak: Int
    var workoutsLogged: Int
    var todayFocus: String?
    var todayExerciseCount: Int
    var weeklyVolume: Double
    var updatedAt: Date

    static let placeholder = WidgetSnapshot(
        streak: 4, workoutsLogged: 23, todayFocus: "Upper Body",
        todayExerciseCount: 6, weeklyVolume: 8200, updatedAt: .now)

    static let empty = WidgetSnapshot(
        streak: 0, workoutsLogged: 0, todayFocus: nil,
        todayExerciseCount: 0, weeklyVolume: 0, updatedAt: .now)

    func write() {
        guard let defaults = AppGroup.defaults,
              let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: AppGroup.snapshotKey)
    }

    static func load() -> WidgetSnapshot {
        guard let defaults = AppGroup.defaults,
              let data = defaults.data(forKey: AppGroup.snapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return .empty }
        return snapshot
    }
}
