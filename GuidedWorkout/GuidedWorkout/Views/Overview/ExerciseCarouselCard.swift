//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import SwiftUI

struct ExerciseCarouselCard: View {

    let index: Int
    let exercise: Exercise
    let progress: ExerciseProgress?
    var onPreview: (() -> Void)? = nil

    private var style: ExerciseStyle { exercise.style }

    var body: some View {
        Button { onPreview?() } label: {
            VStack(spacing: 0) {
                topArt
                metadata
            }
            .frame(width: 240, height: 280)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AppTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.04), lineWidth: 1)
            )
            .softShadow(tint: .black, opacity: 0.08, radius: 16, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Exercise \(index + 1): \(exercise.title)")
        .accessibilityHint("Tap to preview the demo")
    }

    // MARK: - Subviews

    private var topArt: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.canvas)
                .clipShape(
                    .rect(
                        topLeadingRadius: 28,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 28
                    )
                )

            HStack(alignment: .top) {
                indexBadge
                Spacer()
                statusBadge
            }
            .padding(14)

            VStack {
                Spacer()
                Image(systemName: style.symbolName)
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(AppTheme.coral)
                    .padding(.bottom, 18)
            }
            .frame(maxWidth: .infinity)

            playBadge
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .frame(height: 170)
    }

    private var playBadge: some View {
        ZStack {
            Circle()
                .fill(AppTheme.coral)
                .frame(width: 34, height: 34)
                .softShadow(tint: AppTheme.coral, opacity: 0.30, radius: 6, y: 3)
            Image(systemName: "play.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .offset(x: 1)
        }
        .accessibilityHidden(true)
    }

    private var indexBadge: some View {
        Text("\(index + 1)")
            .font(.subheadline.weight(.bold).monospacedDigit())
            .foregroundStyle(.secondary)
            .frame(width: 30, height: 30)
            .background(Circle().fill(AppTheme.surface))
            .overlay(
                Circle().strokeBorder(Color.secondary.opacity(0.20), lineWidth: 1)
            )
    }

    @ViewBuilder
    private var statusBadge: some View {
        if let progress {
            if progress.skipped {
                badgeIcon(systemName: "forward.fill", tint: AppTheme.warningTint)
            } else if progress.completedSets >= exercise.sets {
                badgeIcon(systemName: "checkmark", tint: AppTheme.successTint)
            } else if progress.syncStatus == .pending {
                badgeIcon(systemName: "icloud.slash", tint: AppTheme.warningTint)
            }
        }
    }

    private func badgeIcon(systemName: String, tint: Color) -> some View {
        Image(systemName: systemName)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 26, height: 26)
            .background(Circle().fill(tint))
    }

    private var metadata: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.title)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                Chip(text: exercise.area, tint: .secondary)
                Chip(text: exercise.difficulty.displayName.capitalized, systemImage: "gauge.with.dots.needle.50percent", tint: .secondary)
            }

            HStack(spacing: 14) {
                Label(exercise.target.displayString, systemImage: targetIcon)
                Label("\(exercise.sets) sets", systemImage: "repeat")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var targetIcon: String {
        switch exercise.target {
        case .time: return "timer"
        case .reps: return "number"
        }
    }
}

#if DEBUG
#Preview {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 16) {
            ForEach(Array(SeedData.todaySession.exercises.enumerated()), id: \.element.id) { i, ex in
                ExerciseCarouselCard(index: i, exercise: ex, progress: nil)
            }
        }
        .padding()
    }
    .background(AppTheme.canvas)
}
#endif
