//
//  ProgressMetrics.swift
//  FitnessPro
//
//  Pure aggregation over the completed-workout log. No UI, no I/O — fully
//  testable. Feeds the Progress dashboard charts and stat cards (TODO #3).
//

import Foundation

/// One calendar-week bucket of training, oldest → newest.
struct WeekBucket: Identifiable, Equatable {
    let weekStart: Date
    var sessions: Int
    var volume: Double          // Σ totalVolume (reps × weight)
    var minutes: Int

    var id: Date { weekStart }
}

/// A single session plotted on the volume trend.
struct VolumePoint: Identifiable, Equatable {
    let date: Date
    let volume: Double
    var id: Date { date }
}

/// Personal records surfaced as highlight cards.
struct PersonalRecords: Equatable {
    var heaviestSession: Double = 0     // most volume in one workout
    var longestSession: Int = 0         // minutes
    var bestWeekVolume: Double = 0
    var bestWeekSessions: Int = 0
}

/// Derived dashboard metrics built once from the raw completion log.
struct ProgressMetrics: Equatable {
    let totalWorkouts: Int
    let totalVolume: Double
    let totalMinutes: Int
    let totalSets: Int
    let weeks: [WeekBucket]             // chronological, capped to recent span
    let volumeTrend: [VolumePoint]      // chronological, per session
    let records: PersonalRecords
    let weeklyAverage: Double           // mean sessions/week over active weeks

    var hasData: Bool { totalWorkouts > 0 }

    /// Build metrics from the log. `weekSpan` limits buckets/trend to the most
    /// recent N weeks so charts stay readable.
    init(completions: [CompletedWorkout],
         weekSpan: Int = 8,
         calendar: Calendar = .current,
         now: Date = .now) {

        let sorted = completions.sorted { $0.date < $1.date }

        totalWorkouts = sorted.count
        totalVolume   = sorted.reduce(0) { $0 + $1.totalVolume }
        totalMinutes  = sorted.reduce(0) { $0 + $1.durationMinutes }
        totalSets     = sorted.reduce(0) { $0 + $1.totalSets }

        // Bucket by start-of-week.
        var buckets: [Date: WeekBucket] = [:]
        for c in sorted {
            let start = calendar.startOfWeek(for: c.date)
            var b = buckets[start] ?? WeekBucket(weekStart: start, sessions: 0, volume: 0, minutes: 0)
            b.sessions += 1
            b.volume   += c.totalVolume
            b.minutes  += c.durationMinutes
            buckets[start] = b
        }

        // Keep the most recent `weekSpan` weeks, filling gaps with empties so
        // the bar chart shows a continuous timeline.
        let thisWeekStart = calendar.startOfWeek(for: now)
        var filled: [WeekBucket] = []
        for offset in stride(from: weekSpan - 1, through: 0, by: -1) {
            guard let start = calendar.date(byAdding: .weekOfYear, value: -offset, to: thisWeekStart) else { continue }
            filled.append(buckets[start] ?? WeekBucket(weekStart: start, sessions: 0, volume: 0, minutes: 0))
        }
        weeks = filled

        volumeTrend = sorted.suffix(20).map { VolumePoint(date: $0.date, volume: $0.totalVolume) }

        var prs = PersonalRecords()
        for c in sorted {
            prs.heaviestSession = max(prs.heaviestSession, c.totalVolume)
            prs.longestSession  = max(prs.longestSession, c.durationMinutes)
        }
        for b in buckets.values {
            prs.bestWeekVolume   = max(prs.bestWeekVolume, b.volume)
            prs.bestWeekSessions = max(prs.bestWeekSessions, b.sessions)
        }
        records = prs

        let activeWeeks = buckets.values.filter { $0.sessions > 0 }.count
        weeklyAverage = activeWeeks > 0 ? Double(totalWorkouts) / Double(activeWeeks) : 0
    }
}

extension Calendar {
    /// Start of the week containing `date`, respecting the calendar's `firstWeekday`.
    func startOfWeek(for date: Date) -> Date {
        let comps = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: comps) ?? startOfDay(for: date)
    }
}
