//
//  MainTabView.swift
//  FitnessPro
//
//  Main app shell once the user has a plan: Home, Workouts, Plan, Profile.
//

import SwiftUI

struct MainTabView: View {
    @Environment(AppContainer.self) private var container

    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "house.fill") }

            WorkoutLibraryView(viewModel: container.makeWorkoutLibraryViewModel())
                .tabItem { Label("Workouts", systemImage: "dumbbell.fill") }

            NavigationStack { PlanView() }
                .tabItem { Label("Plan", systemImage: "calendar") }

            NavigationStack { ProgressDashboardView() }
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }

            NavigationStack { ProfileView() }
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .tint(Theme.Colors.accent)
    }
}
