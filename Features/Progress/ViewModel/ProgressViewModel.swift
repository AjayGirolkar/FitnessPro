//
//  ProgressViewModel.swift
//  FitnessPro
//
//  Reads the completion log from AppState and exposes derived metrics for the
//  Progress dashboard. Pure read model — recomputes on appear.
//

import Foundation
import Observation

@MainActor
@Observable
final class ProgressViewModel {
    enum Metric: String, CaseIterable, Identifiable {
        case volume = "Volume"
        case sessions = "Sessions"
        case minutes = "Minutes"
        var id: String { rawValue }
    }

    private let appState: AppState
    private(set) var metrics: ProgressMetrics
    var selectedMetric: Metric = .volume

    init(appState: AppState) {
        self.appState = appState
        self.metrics = ProgressMetrics(completions: appState.completions)
    }

    var streak: Int { appState.streak }

    func refresh() {
        metrics = ProgressMetrics(completions: appState.completions)
    }

    /// Value for the selected metric in a given week — drives the bar chart.
    func value(for week: WeekBucket) -> Double {
        switch selectedMetric {
        case .volume:   return week.volume
        case .sessions: return Double(week.sessions)
        case .minutes:  return Double(week.minutes)
        }
    }
}
