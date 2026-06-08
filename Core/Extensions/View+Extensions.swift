//
//  View+Extensions.swift
//  FitnessPro
//

import SwiftUI

extension View {
    /// Conditionally apply a transform. Keeps view bodies branch-free.
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }

    /// Standard card styling used across feature screens.
    func cardStyle() -> some View {
        self
            .padding(16)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}
