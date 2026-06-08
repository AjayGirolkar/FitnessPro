//
//  WorkoutsViewModel.swift
//  FitnessPro
//
//  @Observable MVVM ViewModel (iOS 17+). Exposes a single view state
//  the View renders declaratively. @MainActor keeps UI mutation on main.
//

import Foundation
import Observation

@MainActor
@Observable
final class WorkoutsViewModel {
    enum ViewState: Equatable {
        case idle
        case loading
        case loaded([Workout])
        case failed(String)
    }

    private(set) var state: ViewState = .idle

    private let service: WorkoutServiceProtocol

    init(service: WorkoutServiceProtocol) {
        self.service = service
    }

    func loadWorkouts() async {
        state = .loading
        do {
            let workouts = try await service.fetchWorkouts()
            state = .loaded(workouts)
        } catch let error as NetworkError {
            state = .failed(error.userMessage)
        } catch {
            state = .failed(NetworkError.unknown.userMessage)
        }
    }
}
