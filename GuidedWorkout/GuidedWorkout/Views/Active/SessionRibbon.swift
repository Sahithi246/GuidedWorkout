//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import SwiftUI

struct SessionRibbon: View {
    let session: WorkoutSession
    let currentIndex: Int
    let progress: [String: ExerciseProgress]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(session.exercises.enumerated()), id: \.element.id) { i, ex in
                pill(for: ex, index: i)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Exercise \(currentIndex + 1) of \(session.exercises.count)")
    }

    private func pill(for ex: Exercise, index: Int) -> some View {
        let p = progress[ex.id]
        let isCurrent = index == currentIndex
        let isDone = p.map { !$0.skipped && $0.completedSets >= ex.sets } ?? false
        let isSkipped = p?.skipped ?? false
        let style = ex.style

        return Capsule()
            .fill(fillStyle(isCurrent: isCurrent, isDone: isDone, isSkipped: isSkipped, style: style))
            .frame(height: 6)
            .frame(maxWidth: .infinity)
            .animation(.snappy(duration: 0.25), value: isCurrent)
    }

    private func fillStyle(isCurrent: Bool, isDone: Bool, isSkipped: Bool, style: ExerciseStyle) -> AnyShapeStyle {
        if isCurrent {
            return AnyShapeStyle(style.gradient)
        } else if isDone {
            return AnyShapeStyle(AppTheme.successTint)
        } else if isSkipped {
            return AnyShapeStyle(AppTheme.warningTint.opacity(0.5))
        } else {
            return AnyShapeStyle(Color.secondary.opacity(0.18))
        }
    }
}
