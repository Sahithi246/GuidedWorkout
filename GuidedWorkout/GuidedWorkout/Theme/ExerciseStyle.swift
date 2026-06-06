//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import SwiftUI

/// Per-exercise visual identity.
///
/// **Color discipline:** every exercise uses the same brand coral/peach. Variety
/// comes from the SF Symbol (5 different icons, one per body area), not from
/// surface tints. This matches how mature fitness apps (Strava, Apple Fitness+)
/// stay disciplined on color while still feeling distinct per content.
struct ExerciseStyle {
    let symbolName: String

    var primary: Color { AppTheme.coral }
    var secondary: Color { AppTheme.peach }
    var gradient: LinearGradient { AppTheme.brandGradient }

    /// Used behind icons and on soft surface decorations. Intentionally neutral
    /// so we don't recreate per-area color washes.
    var softBackground: LinearGradient {
        LinearGradient(
            colors: [AppTheme.coral.opacity(0.12), AppTheme.peach.opacity(0.10)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension Exercise {
    var style: ExerciseStyle {
        ExerciseStyle(symbolName: symbolFor(area: area))
    }

    private func symbolFor(area: String) -> String {
        switch area.lowercased() {
        case "spine":       return "figure.flexibility"
        case "hips":        return "figure.strengthtraining.functional"
        case "core":        return "figure.core.training"
        case "thighs":      return "figure.walk"
        case "upper back":  return "figure.rower"
        default:            return "figure.mind.and.body"
        }
    }
}
