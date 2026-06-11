//
//  RestTimerLiveActivity.swift
//  FitnessProWidgetsExtension
//
//  Lock Screen + Dynamic Island presentation for the active-workout rest
//  timer. Driven by WorkoutActivityAttributes; the countdown updates itself
//  via Text(timerInterval:) so the app doesn't push per-second updates.
//

import SwiftUI
import WidgetKit
import ActivityKit

struct RestTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            lockScreen(context)
                .activityBackgroundTint(WidgetTheme.background.opacity(0.9))
                .activitySystemActionForegroundColor(WidgetTheme.accent)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.workoutFocus, systemImage: "dumbbell.fill")
                        .font(.caption).foregroundStyle(WidgetTheme.accent)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.completedExercises)/\(context.attributes.totalExercises)")
                        .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.exerciseName)
                        .font(.headline).lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    bottom(context)
                }
            } compactLeading: {
                Image(systemName: context.state.isResting ? "timer" : "figure.strengthtraining.traditional")
                    .foregroundStyle(context.state.isResting ? WidgetTheme.warm : WidgetTheme.accent)
            } compactTrailing: {
                if context.state.isResting {
                    Text(timerInterval: Date.now...context.state.restEndsAt, countsDown: true)
                        .font(.caption2.monospacedDigit())
                        .frame(maxWidth: 44)
                        .foregroundStyle(WidgetTheme.warm)
                } else {
                    Text(context.state.setLabel).font(.caption2)
                }
            } minimal: {
                Image(systemName: "flame.fill").foregroundStyle(WidgetTheme.warm)
            }
            .keylineTint(WidgetTheme.accent)
        }
    }

    private func lockScreen(_ context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(context.attributes.workoutFocus, systemImage: "dumbbell.fill")
                    .font(.caption.weight(.semibold)).foregroundStyle(WidgetTheme.accent)
                Spacer()
                Text("\(context.state.completedExercises)/\(context.attributes.totalExercises)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Text(context.state.exerciseName)
                .font(.title3.weight(.bold)).foregroundStyle(.white).lineLimit(1)
            bottom(context)
        }
        .padding()
    }

    @ViewBuilder
    private func bottom(_ context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        HStack {
            Text(context.state.setLabel)
                .font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            if context.state.isResting {
                HStack(spacing: 4) {
                    Image(systemName: "timer").foregroundStyle(WidgetTheme.warm)
                    Text(timerInterval: Date.now...context.state.restEndsAt, countsDown: true)
                        .font(.title3.monospacedDigit().bold())
                        .foregroundStyle(WidgetTheme.warm)
                        .frame(maxWidth: 70)
                }
            } else {
                Label("Working set", systemImage: "bolt.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(WidgetTheme.accent)
            }
        }
    }
}
