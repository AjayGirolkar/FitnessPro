//
//  ProfileView.swift
//  FitnessPro
//
//  User details, fitness profile summary, AI settings and sign out.
//

import SwiftUI

struct ProfileView: View {
    @Environment(AppContainer.self) private var container
    @State private var apiKeyDraft = ""
    @State private var savedFlash = false

    var body: some View {
        let state = container.appState
        ZStack {
            AppBackground(showGlow: false)
            ScrollView {
                VStack(spacing: Theme.Spacing.md) {
                    userHeader(user: state.user)
                    if let profile = state.profile { profileSummary(profile) }
                    aiSettings
                    signOut
                }
                .padding(Theme.Spacing.lg)
            }
            .navigationTitle("Profile")
        }
        .onAppear { apiKeyDraft = container.storedAPIKey }
    }

    // MARK: User

    private func userHeader(user: User?) -> some View {
        SurfaceCard {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: user?.avatarSystemImage ?? "person.crop.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Theme.Gradients.brand)
                VStack(alignment: .leading, spacing: 4) {
                    Text(user?.name ?? "Athlete")
                        .font(.sectionTitle).foregroundStyle(Theme.Colors.textPrimary)
                    Text(user?.email ?? "")
                        .font(.subheadline).foregroundStyle(Theme.Colors.textSecondary)
                    if let provider = user?.provider {
                        TagChip(text: "via \(provider.displayName)", tint: Theme.Colors.secondary)
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: Profile summary

    private func profileSummary(_ p: FitnessProfile) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Your profile").font(.cardTitle).foregroundStyle(Theme.Colors.textPrimary)
                row("Goal", p.goal.title)
                row("Level", p.fitnessLevel.title)
                row("Location", p.location.title)
                row("Schedule", "\(p.daysPerWeek)×/week · \(p.sessionMinutes) min")
                row("BMI", String(format: "%.1f", p.bmi))
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Theme.Colors.textSecondary)
            Spacer()
            Text(value).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.Colors.textPrimary)
        }
    }

    // MARK: AI settings

    private var aiSettings: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Text("AI plan generation").font(.cardTitle).foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    TagChip(text: container.aiEnabled ? "Enabled" : "Off",
                            tint: container.aiEnabled ? Theme.Colors.accent : Theme.Colors.textTertiary)
                }
                Text("Add an Anthropic API key to generate richer, AI-personalized plans. Without one, plans use the built-in smart engine.")
                    .font(.caption).foregroundStyle(Theme.Colors.textSecondary)
                AppTextField(placeholder: "sk-ant-…", text: $apiKeyDraft, systemImage: "key.fill", isSecure: true)
                SecondaryButton(title: savedFlash ? "Saved ✓" : "Save key") {
                    container.updateAPIKey(apiKeyDraft)
                    withAnimation { savedFlash = true }
                    Task { try? await Task.sleep(for: .seconds(1.5)); savedFlash = false }
                }
            }
        }
    }

    // MARK: Sign out

    private var signOut: some View {
        Button(role: .destructive) {
            container.appState.signOut(using: container.authService)
        } label: {
            Text("Sign out")
                .font(.cardTitle)
                .foregroundStyle(Theme.Colors.danger)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Theme.Colors.danger.opacity(0.12), in: RoundedRectangle(cornerRadius: Theme.Radius.md))
        }
        .padding(.top, Theme.Spacing.sm)
    }
}
