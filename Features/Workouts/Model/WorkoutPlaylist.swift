//
//  WorkoutPlaylist.swift
//  FitnessPro
//
//  A user-curated set of exercises saved for replay. Stores exercise IDs
//  (resolved against the catalog at play time) plus the intensity to run them
//  at, so a playlist survives catalog changes and persists across launches.
//

import Foundation

struct WorkoutPlaylist: Identifiable, Codable, Equatable, Sendable {
    var id: UUID = UUID()
    var name: String
    var level: Exercise.Level
    var exerciseIDs: [String]
    var createdAt: Date = .now

    var exerciseCount: Int { exerciseIDs.count }

    var subtitle: String {
        "\(level.displayName) · \(exerciseCount) exercise\(exerciseCount == 1 ? "" : "s")"
    }
}
