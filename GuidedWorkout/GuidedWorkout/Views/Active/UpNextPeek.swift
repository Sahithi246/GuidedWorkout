//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import SwiftUI

/// Compact peek strip showing the next exercise. Adds anticipation while
/// keeping the user grounded in the current workout's arc.
struct UpNextPeek: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(exercise.style.softBackground)
                Image(systemName: exercise.style.symbolName)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(exercise.style.gradient)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text("UP NEXT")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(exercise.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 8) {
                Text(exercise.target.displayString)
                Text("·")
                Text("\(exercise.sets) sets")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        )
    }
}
