//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import SwiftUI

/// Big timer ring with a gradient stroke. Used both for time-based countdown
/// and for the rep-based "elapsed" display (where target is nil).
struct GradientTimerRing: View {
    let elapsed: TimeInterval
    let target: Int?         // nil = open-ended elapsed
    let isRunning: Bool
    let gradient: LinearGradient
    let primaryTint: Color

    private var displayText: String {
        if let target {
            return TimeFormatter.mmss(max(0, target - Int(elapsed.rounded(.down))))
        }
        return TimeFormatter.mmss(elapsed)
    }

    private var progressFraction: Double {
        guard let target, target > 0 else { return 0 }
        return min(1, elapsed / TimeInterval(target))
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.10), lineWidth: 14)

            if target != nil {
                Circle()
                    .trim(from: 0, to: progressFraction)
                    .stroke(gradient, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: progressFraction)
                    .shadow(color: primaryTint.opacity(0.35), radius: 8, y: 4)
            }

            VStack(spacing: 6) {
                Text(displayText)
                    .font(.system(size: 64, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(AppTheme.textPrimary)
                    .contentTransition(.numericText())
                statusPill
            }
        }
        .frame(width: 240, height: 240)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(target == nil ? "Elapsed time" : "Time remaining")
        .accessibilityValue(displayText)
    }

    private var statusPill: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isRunning ? AppTheme.mint : AppTheme.warningTint)
                .frame(width: 6, height: 6)
            Text(isRunning ? "Running" : "Paused")
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(isRunning ? AppTheme.mint : AppTheme.warningTint)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule().fill((isRunning ? AppTheme.mint : AppTheme.warningTint).opacity(0.12))
        )
    }
}
