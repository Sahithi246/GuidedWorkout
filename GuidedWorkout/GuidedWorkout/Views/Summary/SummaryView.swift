//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import SwiftUI

struct SummaryView: View {

    @Environment(ActiveSessionVM.self) private var vm
    @Binding var path: [Route]

    @State private var didCelebrate = false

    var body: some View {
        let summary = vm.liveSummary
        ZStack {
            AppTheme.canvas.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    hero(summary: summary)
                        .onAppear {
                            guard !didCelebrate else { return }
                            didCelebrate = true
                            Haptics.success()
                        }

                    if let milestone = summary.milestone {
                        milestoneBanner(milestone)
                    }

                    statTilesGrid(summary: summary)

                    if vm.hasPendingSync {
                        PendingSyncBanner(
                            count: vm.pendingSyncCount,
                            isRetrying: vm.isRetryingSync,
                            onRetry: { Task { await vm.retryPendingSync() } }
                        )
                        .padding(.horizontal, 20)
                    }

                    perExerciseCarousel
                }
                .padding(.vertical, 12)
                .padding(.bottom, 96)
            }
        }
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            Button("Done") {
                vm.acknowledgeCompletion()
                path.removeAll()
            }
            .buttonStyle(PrimaryButtonStyle(tint: AppTheme.coral))
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .background(.bar)
        }
    }

    // MARK: - Hero

    private func hero(summary: SessionSummary) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(AppTheme.brandGradient)
                .overlay(alignment: .topLeading) {
                    sparkles(opacity: 0.7).offset(x: -30, y: -10)
                }
                .overlay(alignment: .topTrailing) {
                    sparkles(opacity: 0.5).offset(x: 30, y: 20)
                }
                .overlay(alignment: .bottomLeading) {
                    sparkles(opacity: 0.5).offset(x: -10, y: 40)
                }
                .clipped()

            VStack(spacing: 14) {
                ZStack {
                    Circle().fill(.white.opacity(0.20))
                        .frame(width: 100, height: 100)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 4) {
                    Text("Session complete")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text(vm.session?.title ?? "")
                        .font(.subheadline.weight(.medium))
                        .opacity(0.85)
                }
                .foregroundStyle(.white)
            }
            .padding(.vertical, 28)
        }
        .padding(.horizontal, 20)
        .softShadow(tint: AppTheme.coral, opacity: 0.30, radius: 24, y: 14)
    }

    private func sparkles(opacity: Double) -> some View {
        Image(systemName: "sparkles")
            .font(.title2)
            .foregroundStyle(.white.opacity(opacity))
    }

    // MARK: - Milestone

    private func milestoneBanner(_ milestone: Milestone) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(LinearGradient(
                    colors: [AppTheme.peach, AppTheme.coral],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                Image(systemName: milestone.systemImageName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.displayName)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(milestone.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(LinearGradient(
                    colors: [AppTheme.peach.opacity(0.6), AppTheme.coral.opacity(0.3)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ), lineWidth: 1.5)
        )
        .softShadow(tint: AppTheme.coral, opacity: 0.18, radius: 12, y: 6)
        .padding(.horizontal, 20)
    }

    // MARK: - Stat tiles

    private func statTilesGrid(summary: SessionSummary) -> some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 12) {
            // Completed / skipped use semantic colors (green / amber) — they carry meaning.
            // Sets / time stay neutral — pure data.
            statTile(title: "Completed", value: "\(summary.completedExerciseCount)", icon: "checkmark.circle.fill", tint: AppTheme.successTint)
            statTile(title: "Skipped", value: "\(summary.skippedExerciseCount)", icon: "forward.fill", tint: summary.skippedExerciseCount > 0 ? AppTheme.warningTint : .secondary)
            statTile(title: "Total sets", value: "\(summary.totalSetsCompleted)", icon: "repeat", tint: .secondary)
            statTile(title: "Total time", value: TimeFormatter.mmss(summary.totalElapsedSeconds), icon: "clock.fill", tint: .secondary)
        }
        .padding(.horizontal, 20)
    }

    private func statTile(title: String, value: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.secondary.opacity(0.10))
                Image(systemName: icon)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(tint)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(AppTheme.textPrimary)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.black.opacity(0.04), lineWidth: 1)
        )
    }

    // MARK: - Per exercise

    private var perExerciseCarousel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Per exercise")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    if let session = vm.session {
                        ForEach(session.exercises) { ex in
                            perExerciseMiniCard(exercise: ex, progress: vm.progress[ex.id])
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
            .scrollClipDisabled()
        }
    }

    private func perExerciseMiniCard(exercise: Exercise, progress: ExerciseProgress?) -> some View {
        let style = exercise.style
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle().fill(style.softBackground)
                    Image(systemName: style.symbolName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(style.gradient)
                }
                .frame(width: 36, height: 36)
                Spacer()
                statusBadge(progress: progress, exercise: exercise)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)
                Text(exercise.area)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(style.primary)
            }

            Divider().opacity(0.4)

            VStack(alignment: .leading, spacing: 2) {
                Text(detailText(progress: progress, exercise: exercise))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                if let p = progress {
                    Text(TimeFormatter.mmss(p.elapsedSeconds))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(14)
        .frame(width: 180, height: 180, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.black.opacity(0.04), lineWidth: 1)
        )
        .softShadow(tint: .black, opacity: 0.06, radius: 10, y: 4)
    }

    @ViewBuilder
    private func statusBadge(progress: ExerciseProgress?, exercise: Exercise) -> some View {
        if let p = progress {
            if p.skipped {
                badge(icon: "forward.fill", tint: AppTheme.warningTint)
            } else if p.completedSets >= exercise.sets {
                badge(icon: "checkmark", tint: AppTheme.successTint)
            } else if p.completedSets > 0 {
                badge(icon: "circle.lefthalf.filled", tint: AppTheme.lavender)
            }
            if p.syncStatus == .pending {
                badge(icon: "icloud.slash", tint: AppTheme.warningTint)
            }
        }
    }

    private func badge(icon: String, tint: Color) -> some View {
        Image(systemName: icon)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 22, height: 22)
            .background(Circle().fill(tint))
    }

    private func detailText(progress: ExerciseProgress?, exercise: Exercise) -> String {
        guard let p = progress else { return "Not started" }
        if p.skipped { return "Skipped" }
        return "\(p.completedSets) of \(exercise.sets) sets"
    }
}

#if DEBUG
#Preview("Summary – Perfect") {
    NavigationStack {
        SummaryView(path: .constant([.summary]))
            .environment(ActiveSessionVM.previewSummary())
    }
}
#endif
