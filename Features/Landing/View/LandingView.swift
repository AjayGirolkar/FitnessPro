//
//  LandingView.swift
//  FitnessPro
//
//  First-run marketing screen. Sells the value props and routes to auth.
//  Stateless — the root coordinator owns navigation via the callbacks.
//

import SwiftUI

struct LandingView: View {
    var onGetStarted: () -> Void
    var onLogIn: () -> Void

    private let highlights: [Highlight] = [
        .init(icon: "sparkles", title: "AI-built plans",
              detail: "A personalized program crafted around your goals."),
        .init(icon: "dumbbell.fill", title: "800+ exercises",
              detail: "Strength, HIIT, abs, cardio — with form guidance."),
        .init(icon: "slider.horizontal.3", title: "Fully customizable",
              detail: "Tune duration, sets and difficulty any time."),
        .init(icon: "chart.line.uptrend.xyaxis", title: "Track progress",
              detail: "Stay consistent and watch the gains add up.")
    ]

    var body: some View {
        ZStack {
            Theme.Gradients.hero.ignoresSafeArea()
            AppBackground(showGlow: true).opacity(0.0) // keep glow token consistent
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    hero
                    featureList
                    cta
                }
                .padding(Theme.Spacing.lg)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var hero: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.accentSoft)
                    .frame(width: 120, height: 120)
                Image(systemName: "figure.run")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(Theme.Gradients.brand)
            }
            .padding(.top, Theme.Spacing.xxl)

            Text("Your AI fitness coach")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("Answer a few questions and get a workout plan made just for your body, goals and schedule.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Colors.textSecondary)
                .padding(.horizontal, Theme.Spacing.sm)
        }
    }

    private var featureList: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(highlights) { item in
                SurfaceCard {
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: item.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Theme.Colors.accent)
                            .frame(width: 44, height: 44)
                            .background(Theme.Colors.accentSoft, in: RoundedRectangle(cornerRadius: Theme.Radius.sm))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.cardTitle)
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Text(item.detail)
                                .font(.subheadline)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    private var cta: some View {
        VStack(spacing: Theme.Spacing.sm) {
            PrimaryButton(title: "Get started", systemImage: "arrow.right", action: onGetStarted)
            Button(action: onLogIn) {
                Text("I already have an account")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .padding(.top, Theme.Spacing.sm)
    }

    private struct Highlight: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let detail: String
    }
}

#Preview {
    LandingView(onGetStarted: {}, onLogIn: {})
        .preferredColorScheme(.dark)
}
