//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import SwiftUI

struct ActiveExerciseView: View {

    @Environment(ActiveSessionVM.self) private var vm
    @Binding var path: [Route]

    private var exercise: Exercise? { vm.currentExercise }
    private var session: WorkoutSession? { vm.session }

    var body: some View {
        if let exercise, let session, case .exercising(let index) = vm.phase {
            content(exercise: exercise, session: session, index: index)
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func content(exercise: Exercise, session: WorkoutSession, index: Int) -> some View {
        let style = exercise.style

        ZStack {
            AppTheme.canvas.ignoresSafeArea()

            VStack(spacing: 18) {
                topRibbon(session: session, index: index)
                title(exercise: exercise)

                Spacer(minLength: 0)

                ringDisplay(exercise: exercise, style: style)
                setDots(exercise: exercise)

                Spacer(minLength: 0)

                actions(exercise: exercise, style: style)

                upNextStrip(session: session, currentIndex: index)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Top ribbon

    private func topRibbon(session: WorkoutSession, index: Int) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text("Exercise \(index + 1) of \(session.exercises.count)")
                    .font(.caption.weight(.semibold).uppercaseSmallCaps())
                    .foregroundStyle(.secondary)
                Spacer()
            }

            SessionRibbon(
                session: session,
                currentIndex: index,
                progress: vm.progress
            )
        }
    }

    // MARK: - Title

    private func title(exercise: Exercise) -> some View {
        VStack(spacing: 8) {
            Text(exercise.title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            HStack(spacing: 6) {
                Chip(text: exercise.area, systemImage: exercise.style.symbolName, tint: .secondary)
                Chip(text: exercise.difficulty.displayName, systemImage: "gauge.with.dots.needle.50percent", tint: .secondary)
                Chip(text: exercise.target.displayString, systemImage: targetIcon(exercise.target), tint: AppTheme.coral)
            }
        }
    }

    // MARK: - Center display

    @ViewBuilder
    private func ringDisplay(exercise: Exercise, style: ExerciseStyle) -> some View {
        switch exercise.target {
        case .time(let seconds):
            GradientTimerRing(
                elapsed: vm.exerciseTimer.elapsed,
                target: seconds,
                isRunning: vm.exerciseTimer.isRunning,
                gradient: style.gradient,
                primaryTint: style.primary
            )
        case .reps(let count):
            RepCounterRing(
                targetReps: count,
                currentSet: min(vm.currentSetCount + 1, exercise.sets),
                totalSets: exercise.sets,
                elapsed: vm.exerciseTimer.elapsed,
                style: style
            )
        }
    }

    private func setDots(exercise: Exercise) -> some View {
        let allDone = vm.currentSetCount >= exercise.sets
        return VStack(spacing: 8) {
            SetProgressDots(
                completed: vm.currentSetCount,
                total: exercise.sets,
                current: allDone ? nil : vm.currentSetCount + 1,
                size: 16,
                spacing: 12
            )
            .animation(.snappy(duration: 0.25), value: vm.currentSetCount)

            Text(setLabel(exercise: exercise, allDone: allDone))
                .font(.caption.weight(.semibold))
                .foregroundStyle(allDone ? AppTheme.successTint : .secondary)
                .contentTransition(.numericText())
        }
    }

    private func setLabel(exercise: Exercise, allDone: Bool) -> String {
        if allDone { return "All sets complete" }
        let currentSet = vm.currentSetCount + 1
        if exercise.sets == 1 { return "1 set" }
        return "Set \(currentSet) of \(exercise.sets)"
    }

    // MARK: - Actions

    @ViewBuilder
    private func actions(exercise: Exercise, style: ExerciseStyle) -> some View {
        VStack(spacing: 10) {
            primaryActionButton(exercise: exercise, style: style)

            Button {
                Haptics.light()
                vm.skipExercise()
            } label: {
                Label("Skip exercise", systemImage: "forward.fill")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(SecondaryButtonStyle(tint: AppTheme.warningTint))
            .accessibilityLabel("Skip exercise and start rest")
        }
    }

    @ViewBuilder
    private func primaryActionButton(exercise: Exercise, style: ExerciseStyle) -> some View {
        let allSetsDone = vm.currentSetCount >= exercise.sets
        switch exercise.target {
        case .time:
            if vm.exerciseTimer.isRunning {
                Button {
                    Haptics.light()
                    vm.pauseExerciseTimer()
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(PrimaryButtonStyle(tint: AppTheme.warningTint))
                .accessibilityLabel("Pause timer")
            } else if allSetsDone {
                Button { } label: { Text("Complete") }
                    .buttonStyle(PrimaryButtonStyle(tint: AppTheme.successTint))
                    .disabled(true)
            } else {
                Button {
                    Haptics.medium()
                    vm.resumeExerciseTimer()
                } label: {
                    Label("Resume", systemImage: "play.fill")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(PrimaryButtonStyle(tint: style.primary))
                .accessibilityLabel("Resume timer")
            }
        case .reps:
            Button {
                Haptics.medium()
                vm.completeSet()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: allSetsDone ? "checkmark" : "checkmark.circle.fill")
                    Text(allSetsDone ? "All sets complete" : "Complete set \(vm.currentSetCount + 1)")
                }
            }
            .buttonStyle(PrimaryButtonStyle(tint: allSetsDone ? AppTheme.successTint : style.primary))
            .disabled(allSetsDone)
            .accessibilityLabel(allSetsDone ? "All sets complete" : "Complete set \(vm.currentSetCount + 1) of \(exercise.sets)")
        }
    }

    // MARK: - Up next

    @ViewBuilder
    private func upNextStrip(session: WorkoutSession, currentIndex: Int) -> some View {
        if currentIndex + 1 < session.exercises.count {
            UpNextPeek(exercise: session.exercises[currentIndex + 1])
        }
    }

    // MARK: - Helpers

    private func targetIcon(_ target: ExerciseTarget) -> String {
        switch target {
        case .time: return "timer"
        case .reps: return "number"
        }
    }
}

#if DEBUG
#Preview("Active – Time-based") {
    NavigationStack {
        ActiveExerciseView(path: .constant([.active]))
            .environment(ActiveSessionVM.previewExercising(index: 0))
    }
}

#Preview("Active – Rep-based") {
    NavigationStack {
        ActiveExerciseView(path: .constant([.active]))
            .environment(ActiveSessionVM.previewExercising(index: 1))
    }
}
#endif
