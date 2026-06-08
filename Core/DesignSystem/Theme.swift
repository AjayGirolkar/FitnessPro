//
//  Theme.swift
//  FitnessPro
//
//  Central design tokens. One source of truth for color, spacing, radius,
//  typography and gradients so screens stay visually consistent.
//

import SwiftUI

enum Theme {
    // MARK: Color palette
    enum Colors {
        static let accent          = Color(hex: 0x2EC85A)   // energetic green
        static let accentDeep      = Color(hex: 0x12A150)
        static let accentSoft      = Color(hex: 0x2EC85A).opacity(0.15)
        static let secondary       = Color(hex: 0x4E7CFF)   // electric blue
        static let warmAccent      = Color(hex: 0xFF7A3D)   // coral (HIIT/cardio)

        static let background      = Color(hex: 0x0E1116)   // near-black base
        static let surface         = Color(hex: 0x171B22)
        static let surfaceElevated = Color(hex: 0x1F242E)

        static let textPrimary     = Color.white
        static let textSecondary   = Color.white.opacity(0.62)
        static let textTertiary    = Color.white.opacity(0.38)

        static let success         = Color(hex: 0x2EC85A)
        static let warning         = Color(hex: 0xFFB020)
        static let danger          = Color(hex: 0xFF4D4D)

        static let stroke          = Color.white.opacity(0.08)
    }

    // MARK: Spacing scale (4-pt grid)
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs:  CGFloat = 8
        static let sm:  CGFloat = 12
        static let md:  CGFloat = 16
        static let lg:  CGFloat = 24
        static let xl:  CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: Corner radii
    enum Radius {
        static let sm:   CGFloat = 10
        static let md:   CGFloat = 16
        static let lg:   CGFloat = 24
        static let pill: CGFloat = 999
    }

    // MARK: Gradients
    enum Gradients {
        static let brand = LinearGradient(
            colors: [Colors.accent, Colors.accentDeep],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        static let energy = LinearGradient(
            colors: [Colors.warmAccent, Color(hex: 0xFF4D6D)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        static let hero = LinearGradient(
            colors: [Color(hex: 0x12351F), Colors.background],
            startPoint: .top, endPoint: .bottom
        )
    }
}

// MARK: - Color hex helper
extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue:  Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Typography helpers
extension Font {
    static let screenTitle  = Font.system(size: 30, weight: .bold, design: .rounded)
    static let sectionTitle = Font.system(size: 22, weight: .bold, design: .rounded)
    static let cardTitle    = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let metric       = Font.system(size: 28, weight: .heavy, design: .rounded)
    static let pill         = Font.system(size: 13, weight: .semibold, design: .rounded)
}
