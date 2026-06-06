//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import SwiftUI

struct OverviewView: View {

    @Environment(ActiveSessionVM.self) private var vm
    @Binding var path: [Route]
    @State private var showingEndConfirm = false

    var body: some View {
        ZStack {
            AppTheme.canvas.ignoresSafeArea()
            content
        }
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog(
            "End workout and discard progress?",
            isPresented: $showingEndConfirm,
            titleVisibility: .visible
        ) {
            Button("End workout", role: .destructive) {
                Task { await vm.discardSnapshotAndStartFresh() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your sets done so far won't be saved to the summary.")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch vm.phase {
        case .idle, .loading:
            loadingView
        case .loadFailed(let message):
            errorView(message: message)
        case .ready(let session):
            mainScroll(session: session, inProgress: false)
        case .exercising, .resting:
            if let session = vm.session {
                mainScroll(session: session, inProgress: true)
            } else {
                loadingView
            }
        case .completed:
            Color.clear.onAppear {
                if !path.contains(.summary) { path.append(.summary) }
            }
        }
    }

    // MARK: - Loading / error

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().controlSize(.large)
            Text("Loading today's session…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(AppTheme.warningTint)
            Text("Couldn't load today's session")
                .font(.title3.weight(.semibold))
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            Button("Try again") { Task { await vm.retryLoad() } }
                .buttonStyle(PrimaryButtonStyle(tint: AppTheme.coral))
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Main scroll

    private func mainScroll(session: WorkoutSession, inProgress: Bool) -> some View {
        ScrollView {
            VStack(spacing: 22) {
                topBar
                hero(session: session, inProgress: inProgress)

                if vm.hasPendingSync {
                    PendingSyncBanner(
                        count: vm.pendingSyncCount,
                        isRetrying: vm.isRetryingSync,
                        onRetry: { Task { await vm.retryPendingSync() } }
                    )
                    .padding(.horizontal, 20)
                }

                exercisesSection(session: session)

                if inProgress {
                    endSessionButton.padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 12)
            .padding(.bottom, 32)
        }
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Today")
                    .font(.caption.weight(.semibold).uppercaseSmallCaps())
                    .foregroundStyle(.secondary)
                Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            Spacer()
            ZStack {
                Circle().fill(AppTheme.coral.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "sparkles")
                    .foregroundStyle(AppTheme.coral)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Hero

    private func hero(session: WorkoutSession, inProgress: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.brandGradient)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 200, height: 200)
                        .offset(x: 70, y: -80)
                        .blur(radius: 4)
                }
                .overlay(alignment: .bottomLeading) {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 140, height: 140)
                        .offset(x: -40, y: 50)
                }
                .clipped()

            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 8) {
                    Image(systemName: inProgress ? "bolt.fill" : "leaf.fill")
                        .font(.caption.weight(.bold))
                    Text(inProgress ? "Workout in progress" : "Today's reset")
                        .font(.caption.weight(.bold).uppercaseSmallCaps())
                }
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.18)))

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(session.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                }

                HStack(spacing: 14) {
                    statBadge(value: "\(session.estimatedMinutes)", unit: "MIN", icon: "clock")
                    statBadge(value: "\(session.exercises.count)", unit: "EXER", icon: "list.bullet")
                    statBadge(value: "\(session.restSecondsBetweenExercises)s", unit: "REST", icon: "pause.circle")
                }

                heroCTA(session: session, inProgress: inProgress)
                    .padding(.top, 4)
            }
            .padding(22)
        }
        .padding(.horizontal, 20)
        .softShadow(tint: AppTheme.coral, opacity: 0.30, radius: 20, y: 12)
    }

    private func statBadge(value: String, unit: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.caption2.weight(.semibold))
                Text(value).font(.headline.weight(.bold).monospacedDigit())
            }
            Text(unit)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.7))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.16))
        )
    }

    @ViewBuilder
    private func heroCTA(session: WorkoutSession, inProgress: Bool) -> some View {
        if inProgress, let exercise = vm.currentExercise, let index = vm.currentExerciseIndex {
            Button {
                if !path.contains(.active) { path.append(.active) }
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Resume")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.coral)
                        Text("\(exercise.title) · \(index + 1)/\(session.exercises.count)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.coral.opacity(0.7))
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.coral)
                        .padding(8)
                        .background(Circle().fill(AppTheme.coral.opacity(0.12)))
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.white)
                )
            }
            .buttonStyle(.plain)
        } else {
            Button {
                vm.startSession()
                path.append(.active)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                    Text("Start workout").font(.headline.weight(.bold))
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .foregroundStyle(AppTheme.coral)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.white)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var endSessionButton: some View {
        Button(role: .destructive) {
            showingEndConfirm = true
        } label: {
            HStack {
                Image(systemName: "xmark.circle")
                Text("End workout & discard").font(.subheadline.weight(.semibold))
            }
        }
        .buttonStyle(SecondaryButtonStyle(tint: .red))
    }

    // MARK: - Exercises carousel

    private func exercisesSection(session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Exercises")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text("\(session.exercises.count) total")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(session.exercises.enumerated()), id: \.element.id) { i, ex in
                        ExerciseCarouselCard(index: i, exercise: ex, progress: vm.progress[ex.id]) {
                            vm.enterDemo()
                            path.append(.demo(ex))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
            .scrollClipDisabled()
        }
    }
}

#if DEBUG
#Preview("Overview – Ready") {
    NavigationStack {
        OverviewView(path: .constant([]))
            .environment(ActiveSessionVM.previewReady())
    }
}
#endif
