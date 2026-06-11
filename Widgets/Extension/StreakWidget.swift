//
//  StreakWidget.swift
//  FitnessProWidgetsExtension
//
//  Home-screen + Lock-screen widget showing the current streak, lifetime
//  workouts and today's focus. Reads the shared App Group snapshot.
//

import SwiftUI
import WidgetKit

struct StreakEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        let snap = context.isPreview ? .placeholder : WidgetSnapshot.load()
        completion(StreakEntry(date: .now, snapshot: snap))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let entry = StreakEntry(date: .now, snapshot: WidgetSnapshot.load())
        // Refresh hourly; the app also reloads timelines on data changes.
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct StreakWidget: Widget {
    let kind = "FitnessProStreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakWidgetView(entry: entry)
                .containerBackground(WidgetTheme.background, for: .widget)
        }
        .configurationDisplayName("Streak")
        .description("Keep your training streak in sight.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular])
    }
}

struct StreakWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StreakEntry

    var body: some View {
        switch family {
        case .accessoryCircular:  circular
        case .accessoryRectangular: rectangular
        case .systemMedium:       medium
        default:                  small
        }
    }

    private var snap: WidgetSnapshot { entry.snapshot }

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("\(snap.streak)", systemImage: "flame.fill")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(WidgetTheme.warm)
            Text("day streak")
                .font(.caption).foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text(snap.todayFocus ?? "Rest day")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
            Text("\(snap.workoutsLogged) workouts")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var medium: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Label("\(snap.streak)", systemImage: "flame.fill")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(WidgetTheme.warm)
                Text("day streak").font(.caption).foregroundStyle(.secondary)
            }
            Divider().overlay(.white.opacity(0.1))
            VStack(alignment: .leading, spacing: 8) {
                stat("Today", snap.todayFocus ?? "Rest day", WidgetTheme.accent)
                stat("This week", "\(Int(snap.weeklyVolume)) kg", .white)
                stat("All time", "\(snap.workoutsLogged) workouts", .white)
            }
            Spacer(minLength: 0)
        }
    }

    private func stat(_ label: String, _ value: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label.uppercased()).font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
            Text(value).font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(tint).lineLimit(1)
        }
    }

    private var rectangular: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill").foregroundStyle(WidgetTheme.warm)
            VStack(alignment: .leading) {
                Text("\(snap.streak)-day streak").font(.headline)
                Text(snap.todayFocus ?? "Rest day").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var circular: some View {
        VStack(spacing: 0) {
            Image(systemName: "flame.fill").font(.title3)
            Text("\(snap.streak)").font(.system(size: 18, weight: .bold, design: .rounded))
        }
    }
}
