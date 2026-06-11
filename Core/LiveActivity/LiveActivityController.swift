//
//  LiveActivityController.swift
//  FitnessPro
//
//  Starts/updates/ends the rest-timer Live Activity during a workout. Protocol
//  -first so the player VM stays testable (nil controller in unit tests) and
//  ActivityKit lives at the edge.
//

import Foundation
import ActivityKit

@MainActor
protocol LiveActivityControlling: AnyObject {
    func start(focus: String, totalExercises: Int, state: WorkoutActivityAttributes.ContentState)
    func update(_ state: WorkoutActivityAttributes.ContentState)
    func end()
}

@MainActor
final class WorkoutLiveActivityController: LiveActivityControlling {
    private var activity: Activity<WorkoutActivityAttributes>?

    func start(focus: String, totalExercises: Int, state: WorkoutActivityAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled, activity == nil else { return }
        let attributes = WorkoutActivityAttributes(workoutFocus: focus, totalExercises: totalExercises)
        activity = try? Activity.request(
            attributes: attributes,
            content: .init(state: state, staleDate: nil)
        )
    }

    func update(_ state: WorkoutActivityAttributes.ContentState) {
        guard let activity else { return }
        Task { await activity.update(.init(state: state, staleDate: nil)) }
    }

    func end() {
        guard let activity else { return }
        self.activity = nil
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }
}
