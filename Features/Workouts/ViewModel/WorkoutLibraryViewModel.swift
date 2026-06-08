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
    let categories = WorkoutCategory.allCases
    var searchText = ""

    private let provider: ExerciseProviding

    init(provider: ExerciseProviding) {
        self.provider = provider
    }

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
