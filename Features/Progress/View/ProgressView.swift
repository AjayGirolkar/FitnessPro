//
//  ProgressView.swift
//  FitnessPro
//
//  Training dashboard: weekly activity bars (volume/sessions/minutes),
//  per-session volume trend, lifetime totals and personal records. Built on
//  Swift Charts; data comes from the completed-workout log via the VM.
//

import SwiftUI
import Charts

struct ProgressDashboardView: View {
    @Environment(AppContainer.self) private var container
    @State private var viewModel: ProgressViewModel?

    var body: some View {
        ZStack {
            AppBackground(showGlow: false)
            Group {
                if let vm = viewModel {
                    content(vm)
                } else {
                    Color.clear
                }
            }
            .navigationTitle("Progress")
        }
        .onAppear {
            if viewModel == nil {
                viewModel = container.makeProgressViewModel()
            }
            viewModel?.refresh()
        }
    }

    @ViewBuilder
    private func content(_ vm: ProgressViewModel) -> some View {
        @Bindable var vm = vm
        if vm.metrics.hasData {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    statGrid(vm.metrics, streak: vm.streak)

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            HStack {
                                Text("Weekly activity")
                                    .font(.cardTitle).foregroundStyle(Theme.Colors.textPrimary)
                                Spacer()
                            }
                            Picker("Metric", selection: $vm.selectedMetric) {
                                ForEach(ProgressViewModel.Metric.allCases) { Text($0.rawValue).tag($0) }
                            }
                            .pickerStyle(.segmented)
                            weeklyChart(vm)
                        }
                    }

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("Volume trend")
                                .font(.cardTitle).foregroundStyle(Theme.Colors.textPrimary)
                            Text("Total weight moved per session (kg)")
                                .font(.caption).foregroundStyle(Theme.Colors.textSecondary)
                            trendChart(vm.metrics.volumeTrend)
                        }
                    }

                    records(vm.metrics.records)
                }
                .padding(Theme.Spacing.lg)
            }
        } else {
            emptyState
        }
    }

    // MARK: Stat grid

    private func statGrid(_ m: ProgressMetrics, streak: Int) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.sm) {
            statCard("\(m.totalWorkouts)", "workouts", "figure.run", Theme.Colors.accent)
            statCard("\(streak)", "day streak", "flame.fill", Theme.Colors.warmAccent)
            statCard(Self.compact(m.totalVolume), "kg lifted", "scalemass.fill", Theme.Colors.secondary)
            statCard("\(m.totalMinutes)", "minutes", "clock.fill", Theme.Colors.warning)
        }
    }

    private func statCard(_ value: String, _ label: String, _ icon: String, _ tint: Color) -> some View {
        SurfaceCard(padding: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Image(systemName: icon).font(.title3).foregroundStyle(tint)
                Text(value).font(.metric).foregroundStyle(Theme.Colors.textPrimary)
                Text(label).font(.caption).foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }

    // MARK: Charts

    private func weeklyChart(_ vm: ProgressViewModel) -> some View {
        Chart(vm.metrics.weeks) { week in
            BarMark(
                x: .value("Week", week.weekStart, unit: .weekOfYear),
                y: .value(vm.selectedMetric.rawValue, vm.value(for: week))
            )
            .foregroundStyle(Theme.Gradients.brand)
            .cornerRadius(Theme.Radius.sm)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .weekOfYear)) { value in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(Theme.Colors.stroke)
                AxisValueLabel().foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .frame(height: 180)
    }

    private func trendChart(_ points: [VolumePoint]) -> some View {
        Chart(points) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Volume", point.volume)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(Theme.Colors.accent)
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

            AreaMark(
                x: .value("Date", point.date),
                y: .value("Volume", point.volume)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(LinearGradient(
                colors: [Theme.Colors.accent.opacity(0.25), .clear],
                startPoint: .top, endPoint: .bottom))

            PointMark(
                x: .value("Date", point.date),
                y: .value("Volume", point.volume)
            )
            .foregroundStyle(Theme.Colors.accent)
            .symbolSize(28)
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(Theme.Colors.stroke)
                AxisValueLabel().foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .frame(height: 200)
    }

    // MARK: Records

    private func records(_ r: PersonalRecords) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Label("Personal records", systemImage: "trophy.fill")
                    .font(.cardTitle).foregroundStyle(Theme.Colors.textPrimary)
                recordRow("Heaviest session", "\(Self.compact(r.heaviestSession)) kg")
                recordRow("Longest session", "\(r.longestSession) min")
                recordRow("Best week (volume)", "\(Self.compact(r.bestWeekVolume)) kg")
                recordRow("Best week (sessions)", "\(r.bestWeekSessions)")
            }
        }
    }

    private func recordRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Theme.Colors.textSecondary)
            Spacer()
            Text(value).font(.subheadline.weight(.bold)).foregroundStyle(Theme.Colors.accent)
        }
    }

    // MARK: Empty

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle).foregroundStyle(Theme.Colors.accent)
            Text("No workouts logged yet")
                .font(.cardTitle).foregroundStyle(Theme.Colors.textPrimary)
            Text("Finish a session and your progress charts will appear here.")
                .font(.subheadline).foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.xl)
    }

    // MARK: Formatting

    /// 12500 → "12.5k", 950 → "950".
    static func compact(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.1fk", value / 1000)
        }
        return String(format: "%.0f", value)
    }
}
