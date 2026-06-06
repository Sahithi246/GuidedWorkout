//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import SwiftUI

struct RestView: View {

    @Environment(ActiveSessionVM.self) private var vm
    @Binding var path: [Route]

    private var nextExercise: Exercise? { vm.currentExercise }
    private var session: WorkoutSession? { vm.session }

    var body: some View {
        if let nextExercise, let session, case .resting(let nextIndex) = vm.phase {
            content(nextExercise: nextExercise, session: session, nextIndex: nextIndex)
        } else {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func content(nextExercise: Exercise, session: WorkoutSession, nextIndex: Int) -> some View {
        let style = nextExercise.style
        return ZStack {
            AppTheme.canvas.ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer()

                header

                countdownRing(session: session, style: style)

                upNextHero(nextExercise: nextExercise, style: style)

                Spacer()

                actions(nextIndex: nextIndex)
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 18)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "leaf.fill").font(.caption)
                Text("REST")
                    .font(.caption.weight(.bold).uppercaseSmallCaps())
            }
            .foregroundStyle(AppTheme.coral)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Capsule().fill(AppTheme.coral.opacity(0.14)))

            Text("Take a breath")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
        }
    }

    // MARK: - Countdown

    private func countdownRing(session: WorkoutSession, style: ExerciseStyle) -> some View {
        let total = TimeInterval(session.restSecondsBetweenExercises)
        let remaining = TimeInterval(vm.restRemainingSeconds)
        let progress = total > 0 ? min(1, max(0, (total - remaining) / total)) : 0

        return ZStack {
            Circle()
                .stroke(style.primary.opacity(0.10), lineWidth: 16)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(style.gradient, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: style.primary.opacity(0.35), radius: 12, y: 6)
                .animation(.linear(duration: 0.1), value: progress)

            VStack(spacing: 4) {
                Text(TimeFormatter.mmss(vm.restRemainingSeconds))
                    .font(.system(size: 80, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(AppTheme.textPrimary)
                    .contentTransition(.numericText())
                Text("REMAINING")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 240, height: 240)
        .accessibilityLabel("Rest remaining")
        .accessibilityValue(TimeFormatter.mmss(vm.restRemainingSeconds))
    }

    // MARK: - Up next

    private func upNextHero(nextExercise: Exercise, style: ExerciseStyle) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(style.softBackground)
                Image(systemName: style.symbolName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(style.gradient)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text("UP NEXT")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(style.primary)
                Text(nextExercise.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                HStack(spacing: 10) {
                    HStack(spacing: 3) {
                        Image(systemName: nextExercise.target.isTimeBased ? "timer" : "number")
                            .font(.caption2)
                        Text(nextExercise.target.displayString)
                    }
                    Text("•")
                    Text("\(nextExercise.sets) sets")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(style.primary.opacity(0.20), lineWidth: 1)
        )
        .softShadow(tint: .black, opacity: 0.08, radius: 14, y: 6)
        .padding(.horizontal, 20)
    }

    // MARK: - Actions

    private func actions(nextIndex: Int) -> some View {
        VStack(spacing: 10) {
            Button {
                Haptics.medium()
                vm.skipRest()
            } label: {
                Label("Skip rest", systemImage: "forward.fill")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(PrimaryButtonStyle(tint: AppTheme.coral))
            .accessibilityLabel("Skip rest and start next exercise")

            Button {
                vm.goToPreviousExercise()
            } label: {
                Label("Previous exercise", systemImage: "chevron.left")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(SecondaryButtonStyle(tint: .secondary))
            .disabled(nextIndex == 0)
        }
    }
}

#if DEBUG
#Preview("Rest") {
    NavigationStack {
        RestView(path: .constant([.active]))
            .environment(ActiveSessionVM.previewResting(nextIndex: 1))
    }
}
#endif
