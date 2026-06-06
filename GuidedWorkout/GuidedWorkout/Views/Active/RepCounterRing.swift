//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import SwiftUI

/// Big rep target display used in place of the ring for rep-based exercises.
struct RepCounterRing: View {
    let targetReps: Int
    let currentSet: Int
    let totalSets: Int
    let elapsed: TimeInterval
    let style: ExerciseStyle

    var body: some View {
        ZStack {
            Circle().fill(style.softBackground)
            Circle().stroke(style.primary.opacity(0.25), lineWidth: 2)

            VStack(spacing: 4) {
                Text("\(targetReps)")
                    .font(.system(size: 92, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(style.gradient)
                Text("REPS")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(style.primary.opacity(0.7))
                Text("Set \(currentSet) of \(totalSets)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.top, 2)
                Text(TimeFormatter.mmss(elapsed))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 240, height: 240)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(targetReps) reps, set \(currentSet) of \(totalSets)")
    }
}
