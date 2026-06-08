//
//  AuthView.swift
//  FitnessPro
//
//  Combined Login / Sign Up screen. Mode toggles between the two so the
//  form, social buttons and validation live in one place.
//

import SwiftUI

struct AuthView: View {
    enum Mode: String, CaseIterable {
        case signIn = "Log In"
        case signUp = "Sign Up"
    }

    @State var viewModel: AuthViewModel
    @State private var mode: Mode = .signIn

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    header

                    modePicker

                    fields

                    if let message = viewModel.errorMessage {
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(Theme.Colors.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    PrimaryButton(
                        title: mode == .signIn ? "Log In" : "Create Account",
                        isLoading: viewModel.isWorking
                    ) {
                        Task { mode == .signIn ? await viewModel.signIn() : await viewModel.signUp() }
                    }

                    divider

                    socialButtons

                    #if DEBUG
                    demoSection
                    #endif
                }
                .padding(Theme.Spacing.lg)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Sections

    private var header: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "bolt.heart.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.Gradients.brand)
                .padding(.top, Theme.Spacing.xl)
            Text(mode == .signIn ? "Welcome back" : "Join FitnessPro")
                .font(.screenTitle)
                .foregroundStyle(Theme.Colors.textPrimary)
            Text(mode == .signIn ? "Log in to continue your journey" : "Create your account in seconds")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    private var modePicker: some View {
        Picker("Mode", selection: $mode.animation()) {
            ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
    }

    private var fields: some View {
        VStack(spacing: Theme.Spacing.sm) {
            if mode == .signUp {
                AppTextField(placeholder: "Full name", text: $viewModel.name,
                             systemImage: "person", textContentType: .name)
            }
            AppTextField(placeholder: "Email", text: $viewModel.email,
                         systemImage: "envelope", keyboard: .emailAddress,
                         textContentType: .emailAddress)
            AppTextField(placeholder: "Password", text: $viewModel.password,
                         systemImage: "lock", isSecure: true,
                         textContentType: mode == .signIn ? .password : .newPassword)
        }
    }

    private var divider: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Rectangle().fill(Theme.Colors.stroke).frame(height: 1)
            Text("or continue with")
                .font(.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
                .fixedSize()
            Rectangle().fill(Theme.Colors.stroke).frame(height: 1)
        }
    }

    private var socialButtons: some View {
        VStack(spacing: Theme.Spacing.sm) {
            SecondaryButton(title: "Continue with Google", systemImage: "globe") {
                Task { await viewModel.continueWithGoogle() }
            }
            SecondaryButton(title: "Continue with Apple", systemImage: "apple.logo") {
                Task { await viewModel.continueWithApple() }
            }
        }
    }

    #if DEBUG
    /// Dev-only shortcuts so the app flow can be exercised without typing
    /// real credentials. Stripped from release builds.
    private var demoSection: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Button {
                Task { await viewModel.signInAsDemo() }
            } label: {
                Label("Skip — use demo account", systemImage: "wand.and.stars")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Colors.accent)
            }
            .disabled(viewModel.isWorking)

            Button("Prefill demo credentials") {
                viewModel.fillDemoCredentials()
            }
            .font(.caption)
            .foregroundStyle(Theme.Colors.textTertiary)
        }
        .padding(.top, Theme.Spacing.xs)
    }
    #endif
}

#Preview {
    NavigationStack {
        AuthView(viewModel: AuthViewModel(service: MockAuthService(store: UserDefaultsStore())))
    }
    .preferredColorScheme(.dark)
}
