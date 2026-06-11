//
//  FitnessProWidgetBundle.swift
//  FitnessProWidgetsExtension
//
//  Entry point for the widget extension. Bundles the home-screen streak
//  widget and the rest-timer Live Activity.
//

import SwiftUI
import WidgetKit

/// Shared brand palette (kept local so the extension has no app dependency).
enum WidgetTheme {
    static let accent     = Color(red: 0x2E / 255, green: 0xC8 / 255, blue: 0x5A / 255)
    static let warm       = Color(red: 0xFF / 255, green: 0x7A / 255, blue: 0x3D / 255)
    static let background = Color(red: 0x0E / 255, green: 0x11 / 255, blue: 0x16 / 255)
    static let surface    = Color(red: 0x17 / 255, green: 0x1B / 255, blue: 0x22 / 255)
}

@main
struct FitnessProWidgetBundle: WidgetBundle {
    var body: some Widget {
        StreakWidget()
        RestTimerLiveActivity()
    }
}
