//
//  Components.swift
//  FitnessPro
//
//  Reusable SwiftUI building blocks styled from Theme tokens. Screens
//  compose these instead of re-styling primitives ad hoc.
//

import SwiftUI

// MARK: - Backgrounds

/// Full-bleed dark app background with an optional brand glow at the top.
struct AppBackground: View {
    var showGlow: Bool = true

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            if showGlow {
                Theme.Colors.accent
                    .opacity(0.18)
                    .frame(width: 320, height: 320)
                    .blur(radius: 160)
                    .offset(y: -260)
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Buttons

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                if isLoading {
                    ProgressView().tint(.black)
                } else {
                    if let systemImage { Image(systemName: systemImage) }
                    Text(title)
                }
            }
            .font(.cardTitle)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Theme.Gradients.brand, in: RoundedRectangle(cornerRadius: Theme.Radius.md))
            .opacity(isEnabled && !isLoading ? 1 : 0.5)
        }
        .disabled(!isEnabled || isLoading)
    }
}

struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(.cardTitle)
            .foregroundStyle(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Theme.Colors.surfaceElevated, in: RoundedRectangle(cornerRadius: Theme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .stroke(Theme.Colors.stroke, lineWidth: 1)
            )
        }
    }
}

// MARK: - Surfaces

/// Standard elevated card surface.
struct SurfaceCard<Content: View>: View {
    var padding: CGFloat = Theme.Spacing.md
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .stroke(Theme.Colors.stroke, lineWidth: 1)
            )
    }
}

/// Selectable option used across onboarding quizzes.
struct OptionCard: View {
    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isSelected ? .black : Theme.Colors.accent)
                        .frame(width: 44, height: 44)
                        .background(
                            isSelected ? AnyShapeStyle(Theme.Colors.accent) : AnyShapeStyle(Theme.Colors.accentSoft),
                            in: RoundedRectangle(cornerRadius: Theme.Radius.sm)
                        )
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.cardTitle)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Theme.Colors.accent : Theme.Colors.textTertiary)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .stroke(isSelected ? Theme.Colors.accent : Theme.Colors.stroke,
                            lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Small bits

struct TagChip: View {
    let text: String
    var tint: Color = Theme.Colors.accent

    var body: some View {
        Text(text)
            .font(.pill)
            .foregroundStyle(tint)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 6)
            .background(tint.opacity(0.15), in: Capsule())
    }
}

struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.sectionTitle)
                .foregroundStyle(Theme.Colors.textPrimary)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Colors.accent)
            }
        }
    }
}

/// Animated circular progress ring for onboarding / plan progress.
struct ProgressRing: View {
    let progress: Double          // 0...1
    var lineWidth: CGFloat = 8
    var tint: Color = Theme.Colors.accent

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.Colors.surfaceElevated, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: progress)
        }
    }
}

/// Linear step progress bar used in onboarding.
struct StepProgressBar: View {
    let current: Int
    let total: Int

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.Colors.surfaceElevated)
                Capsule()
                    .fill(Theme.Gradients.brand)
                    .frame(width: geo.size.width * fraction)
                    .animation(.easeInOut(duration: 0.3), value: fraction)
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Inputs

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    var systemImage: String? = nil
    var isSecure: Bool = false
    var keyboard: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .frame(width: 20)
            }
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .foregroundStyle(Theme.Colors.textPrimary)
            .keyboardType(keyboard)
            .textContentType(textContentType)
            .autocorrectionDisabled()
            .textInputAutocapitalization(keyboard == .emailAddress ? .never : .sentences)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .stroke(Theme.Colors.stroke, lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        AppBackground()
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                SectionHeader(title: "Components", actionTitle: "See all") {}
                OptionCard(title: "Lose weight", subtitle: "Burn fat, stay lean",
                           systemImage: "flame.fill", isSelected: true) {}
                OptionCard(title: "Build muscle", subtitle: "Strength & size",
                           systemImage: "dumbbell.fill", isSelected: false) {}
                HStack { TagChip(text: "HIIT"); TagChip(text: "Beginner", tint: Theme.Colors.secondary) }
                AppTextField(placeholder: "Email", text: .constant(""), systemImage: "envelope")
                PrimaryButton(title: "Continue", systemImage: "arrow.right") {}
                SecondaryButton(title: "Skip for now") {}
                StepProgressBar(current: 3, total: 6)
            }
            .padding()
        }
    }
    .preferredColorScheme(.dark)
}
