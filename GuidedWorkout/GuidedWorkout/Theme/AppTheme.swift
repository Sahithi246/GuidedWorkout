//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import SwiftUI

/// Warm wellness palette. Coral, peach, mint accents on a soft canvas.
enum AppTheme {
    static let canvas = Color(red: 0.99, green: 0.97, blue: 0.95)
    static let surface = Color(.systemBackground)
    static let textPrimary = Color(red: 0.15, green: 0.13, blue: 0.18)
    static let textSecondary = Color.secondary

    static let coral = Color(red: 1.00, green: 0.55, blue: 0.45)
    static let peach = Color(red: 1.00, green: 0.78, blue: 0.60)
    static let mint = Color(red: 0.40, green: 0.80, blue: 0.65)
    static let teal = Color(red: 0.40, green: 0.70, blue: 0.80)
    static let lavender = Color(red: 0.65, green: 0.55, blue: 0.90)
    static let blush = Color(red: 0.95, green: 0.55, blue: 0.65)

    static let warningTint = Color(red: 0.95, green: 0.60, blue: 0.25)
    static let successTint = mint

    /// Default brand gradient (coral → peach).
    static let brandGradient = LinearGradient(
        colors: [coral, peach],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension View {
    /// Soft drop shadow used throughout the redesigned UI.
    func softShadow(tint: Color = .black, opacity: Double = 0.08, radius: CGFloat = 16, y: CGFloat = 8) -> some View {
        shadow(color: tint.opacity(opacity), radius: radius, x: 0, y: y)
    }
}
