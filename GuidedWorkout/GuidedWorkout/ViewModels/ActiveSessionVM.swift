//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import Foundation
import SwiftUI
import Observation

/// The single source of truth for an in-progress workout session.
///
/// Owns the state machine (`SessionPhase`), per-exercise progress, both timers,
/// and the local persistence + remote sync coordination. Views observe properties
/// directly; they never mutate state outside of the methods on this VM.
@Observable
final class ActiveSessionVM {

    // MARK: - Dependencies

    private let service: WorkoutServiceProtocol
    private let store: SessionStoreProtocol

    // MARK: - Public observable state

    private(set) var phase: SessionPhase = .idle
    private(set) var session: WorkoutSession?
    private(set) var progress: [String: ExerciseProgress] = [:]
    private(set) var currentSetCount: Int = 0
    private(set) var isRetryingSync: Bool = false
    private(set) var hasResumableSnapshot: Bool = false

    let exerciseTimer = WorkoutTimer()
    let restTimer = WorkoutTimer()

    // MARK: - Private state

    private var startedAt: Date = Date()
    @ObservationIgnored private var autoCompleteTask: Task<Void, Never>?
    @ObservationIgnored private var restCompleteTask: Task<Void, Never>?
    @ObservationIgnored private var exerciseWasRunningBeforeDemo: Bool = false

    // MARK: - Init

    init(service: WorkoutServiceProtocol, store: SessionStoreProtocol) {
        self.service = service
        self.store = store
    }

    // MARK: - Bootstrap

    /// Called once at launch. Restores a persisted snapshot if any, else fetches.
    func bootstrap() async {
        if let snapshot = try? store.load() {
            hasResumableSnapshot = true
            restore(from: snapshot)
        } else {
            await loadToday()
        }
    }

    /// Discards any persisted snapshot and starts a fresh fetch.
    func discardSnapshotAndStartFresh() async {
        try? store.clear()
        hasResumableSnapshot = false
        resetTransientState()
        await loadToday()
    }

    func loadToday() async {
        phase = .loading
        do {
            let s = try await service.fetchTodaySession()
            session = s
            progress = Dictionary(
                uniqueKeysWithValues: s.exercises.map { ($0.id, ExerciseProgress.initial(for: $0.id)) }
            )
            phase = .ready(s)
        } catch {
            phase = .loadFailed(message: error.localizedDescription)
        }
    }

    func retryLoad() async { await loadToday() }

    // MARK: - Session control

    func startSession() {
        guard session != nil, case .ready = phase else { return }
        startedAt = Date()
        moveTo(exerciseIndex: 0)
        persistSnapshot()
    }

    func resumeExerciseTimer() {
        guard case .exercising = phase else { return }
        exerciseTimer.resume()
        scheduleAutoSetCompletion()
        persistSnapshot()
    }

    func pauseExerciseTimer() {
        guard case .exercising = phase else { return }
        exerciseTimer.pause()
        cancelAutoSetCompletion()
        persistSnapshot()
    }

    // MARK: - Set / exercise mutations

    func completeSet() {
        guard case .exercising = phase,
              let session,
              let ex = currentExercise else { return }
        guard currentSetCount < ex.sets else { return }

        currentSetCount += 1

        var p = progress[ex.id] ?? .initial(for: ex.id)
        p.completedSets = currentSetCount
        p.elapsedSeconds = max(p.elapsedSeconds, Int(exerciseTimer.snapshot()))
        p.skipped = false
        progress[ex.id] = p

        if currentSetCount >= ex.sets {
            finishCurrentExercise(skipped: false, session: session)
        } else {
            // Within same exercise: reset timer for next set if time-based.
            if case .time = ex.target {
                exerciseTimer.reset()
                exerciseTimer.start()
                scheduleAutoSetCompletion()
            }
            persistSnapshot()
        }
    }

    func skipExercise() {
        guard case .exercising = phase, let session, let ex = currentExercise else { return }
        var p = progress[ex.id] ?? .initial(for: ex.id)
        p.skipped = true
        p.completedSets = currentSetCount
        p.elapsedSeconds = max(p.elapsedSeconds, Int(exerciseTimer.snapshot()))
        progress[ex.id] = p
        finishCurrentExercise(skipped: true, session: session)
    }

    func goToPreviousExercise() {
        switch phase {
        case .exercising(let index) where index > 0:
            cancelAutoSetCompletion()
            exerciseTimer.reset()
            moveTo(exerciseIndex: index - 1)
            persistSnapshot()
        case .resting(let nextIndex) where nextIndex > 0:
            cancelRestCompletion()
            restTimer.reset()
            moveTo(exerciseIndex: nextIndex - 1)
            persistSnapshot()
        default:
            break
        }
    }

    func goToNextExercise() {
        // Pure navigation forward (does NOT mark skipped). Skipping with intent uses skipExercise().
        switch phase {
        case .exercising(let index):
            guard let session, index + 1 < session.exercises.count else { return }
            cancelAutoSetCompletion()
            exerciseTimer.reset()
            moveTo(exerciseIndex: index + 1)
            persistSnapshot()
        case .resting:
            skipRest()
        default:
            break
        }
    }

    private func finishCurrentExercise(skipped: Bool, session: WorkoutSession) {
        guard case .exercising(let index) = phase else { return }
        cancelAutoSetCompletion()
        exerciseTimer.reset()

        Task { await self.attemptRemoteCompleteExercise(forIndex: index) }

        let isLast = index >= session.exercises.count - 1
        if isLast {
            completeSession()
        } else {
            beginRest(nextIndex: index + 1)
        }
        persistSnapshot()
    }

    // MARK: - Remote sync coordination (local-first)

    private func attemptRemoteCompleteExercise(forIndex index: Int) async {
        guard let session, index < session.exercises.count else { return }
        let exId = session.exercises[index].id
        guard var p = progress[exId] else { return }

        p.syncStatus = .pending
        progress[exId] = p
        persistSnapshot()

        do {
            try await service.completeExercise(sessionId: session.id, exerciseId: exId, progress: p)
            var updated = p
            updated.syncStatus = .synced
            progress[exId] = updated
            persistSnapshot()
        } catch {
            // Stay in `.pending` — surfaced in UI for retry.
        }
    }

    func retryPendingSync() async {
        guard let session, !isRetryingSync else { return }
        isRetryingSync = true
        defer { isRetryingSync = false }

        for ex in session.exercises {
            guard let p = progress[ex.id], p.syncStatus == .pending else { continue }
            do {
                try await service.completeExercise(sessionId: session.id, exerciseId: ex.id, progress: p)
                var updated = p
                updated.syncStatus = .synced
                progress[ex.id] = updated
                persistSnapshot()
            } catch {
                // Stays pending; user can try again.
            }
        }
    }

    // MARK: - Movement

    private func moveTo(exerciseIndex index: Int) {
        guard let session, session.exercises.indices.contains(index) else { return }
        phase = .exercising(index: index)
        let exercise = session.exercises[index]
        currentSetCount = progress[exercise.id]?.completedSets ?? 0

        exerciseTimer.reset()
        exerciseTimer.start()
        if case .time = exercise.target {
            scheduleAutoSetCompletion()
        }
    }

    // MARK: - Rest

    private func beginRest(nextIndex: Int) {
        phase = .resting(nextIndex: nextIndex)
        restTimer.reset()
        restTimer.start()
        scheduleRestCompletion()
    }

    func skipRest() {
        guard case .resting(let nextIndex) = phase else { return }
        cancelRestCompletion()
        restTimer.reset()
        moveTo(exerciseIndex: nextIndex)
        persistSnapshot()
    }

    private func scheduleRestCompletion() {
        guard let session else { return }
        let target = TimeInterval(session.restSecondsBetweenExercises)
        cancelRestCompletion()
        restCompleteTask = Task { [weak self] in
            guard let self else { return }
            let remaining = target - self.restTimer.snapshot()
            if remaining > 0 {
                try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            }
            guard !Task.isCancelled,
                  case .resting = self.phase,
                  self.restTimer.snapshot() >= target else { return }
            self.skipRest()
        }
    }

    private func cancelRestCompletion() {
        restCompleteTask?.cancel()
        restCompleteTask = nil
    }

    // MARK: - Auto set completion (time-based)

    private func scheduleAutoSetCompletion() {
        guard case .exercising = phase,
              let ex = currentExercise,
              case .time(let targetSec) = ex.target else { return }
        let target = TimeInterval(targetSec)
        cancelAutoSetCompletion()
        autoCompleteTask = Task { [weak self] in
            guard let self else { return }
            let remaining = target - self.exerciseTimer.snapshot()
            if remaining > 0 {
                try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            }
            guard !Task.isCancelled,
                  case .exercising = self.phase,
                  self.exerciseTimer.isRunning,
                  self.exerciseTimer.snapshot() >= target else { return }
            self.completeSet()
        }
    }

    private func cancelAutoSetCompletion() {
        autoCompleteTask?.cancel()
        autoCompleteTask = nil
    }

    // MARK: - Session completion

    private func completeSession() {
        let summary = makeSummary()
        phase = .completed(summary)
        Task {
            do { try await service.completeSession(summary) } catch { /* swallow — local copy preserved */ }
        }
        try? store.clear()
    }

    private func makeSummary() -> SessionSummary {
        guard let session else {
            return SessionSummary(
                sessionId: "", scheduleId: "", workoutId: "",
                completedExerciseCount: 0, skippedExerciseCount: 0,
                totalSetsCompleted: 0, totalElapsedSeconds: 0, milestone: nil
            )
        }
        let values = session.exercises.compactMap { progress[$0.id] }
        let completedCount = zip(session.exercises, values).filter { ex, p in
            !p.skipped && p.completedSets >= ex.sets
        }.count
        let skippedCount = values.filter { $0.skipped }.count
        let totalSets = values.reduce(0) { $0 + $1.completedSets }
        let totalElapsed = values.reduce(0) { $0 + $1.elapsedSeconds }
        let milestone: Milestone? =
            (completedCount == session.exercises.count && skippedCount == 0) ? .perfectSession : nil
        return SessionSummary(
            sessionId: session.id,
            scheduleId: session.scheduleId,
            workoutId: session.workoutId,
            completedExerciseCount: completedCount,
            skippedExerciseCount: skippedCount,
            totalSetsCompleted: totalSets,
            totalElapsedSeconds: totalElapsed,
            milestone: milestone
        )
    }

    // MARK: - Demo navigation hooks

    func enterDemo() {
        exerciseWasRunningBeforeDemo = exerciseTimer.isRunning
        if exerciseTimer.isRunning {
            exerciseTimer.pause()
            cancelAutoSetCompletion()
        }
        persistSnapshot()
    }

    func exitDemo() {
        if exerciseWasRunningBeforeDemo, case .exercising = phase {
            exerciseTimer.resume()
            scheduleAutoSetCompletion()
        }
        exerciseWasRunningBeforeDemo = false
        persistSnapshot()
    }

    // MARK: - Lifecycle

    func handleScenePhase(_ newPhase: ScenePhase) {
        switch newPhase {
        case .background, .inactive:
            if case .exercising = phase, exerciseTimer.isRunning {
                exerciseTimer.pause()
                cancelAutoSetCompletion()
            }
            persistSnapshot()
        case .active:
            if case .resting = phase, let session {
                let target = TimeInterval(session.restSecondsBetweenExercises)
                if restTimer.snapshot() >= target {
                    skipRest()
                } else {
                    scheduleRestCompletion()
                }
            }
        @unknown default:
            break
        }
    }

    // MARK: - Snapshot restore / persist

    private func restore(from snapshot: SessionSnapshot) {
        session = snapshot.session
        progress = Dictionary(uniqueKeysWithValues: snapshot.progress.map { ($0.exerciseId, $0) })
        startedAt = snapshot.startedAt

        switch snapshot.phase {
        case .exercising(let index):
            phase = .exercising(index: index)
            let exercise = snapshot.session.exercises[index]
            currentSetCount = progress[exercise.id]?.completedSets ?? 0
            exerciseTimer.seed(elapsed: TimeInterval(snapshot.elapsedOnCurrent))
            // Stay paused — user explicitly resumes from the active screen.
        case .resting(let nextIndex):
            phase = .resting(nextIndex: nextIndex)
            let total = TimeInterval(snapshot.session.restSecondsBetweenExercises)
            let savedRemaining = TimeInterval(snapshot.restRemainingSeconds ?? snapshot.session.restSecondsBetweenExercises)
            // Rest is wall-clock — account for time the app was suspended/killed.
            let secondsSinceLastSave = Date().timeIntervalSince(snapshot.lastUpdatedAt)
            let actualRemaining = max(0, savedRemaining - secondsSinceLastSave)
            if actualRemaining <= 0 {
                // Rest already elapsed while the app was away — go straight to next exercise.
                restTimer.reset()
                moveTo(exerciseIndex: nextIndex)
            } else {
                let elapsedOnRest = max(0, total - actualRemaining)
                restTimer.seed(elapsed: elapsedOnRest)
                restTimer.start()
                scheduleRestCompletion()
            }
        case .completed:
            phase = .completed(makeSummary())
        }
    }

    private func resetTransientState() {
        cancelAutoSetCompletion()
        cancelRestCompletion()
        exerciseTimer.reset()
        restTimer.reset()
        progress = [:]
        session = nil
        currentSetCount = 0
        phase = .idle
    }

    private func persistSnapshot() {
        guard let session else { return }
        let persistedPhase: PersistedPhase
        switch phase {
        case .exercising(let i): persistedPhase = .exercising(index: i)
        case .resting(let i): persistedPhase = .resting(nextIndex: i)
        case .completed: return     // clear() already called
        case .ready, .idle, .loading, .loadFailed: return
        }

        let snapshot = SessionSnapshot(
            session: session,
            progress: session.exercises.compactMap { progress[$0.id] },
            phase: persistedPhase,
            elapsedOnCurrent: Int(exerciseTimer.snapshot()),
            restRemainingSeconds: {
                if case .resting = phase {
                    let remaining = TimeInterval(session.restSecondsBetweenExercises) - restTimer.snapshot()
                    return Int(max(0, remaining))
                }
                return nil
            }(),
            startedAt: startedAt,
            lastUpdatedAt: Date()
        )
        try? store.save(snapshot)
    }

    // MARK: - Derived

    var currentExercise: Exercise? {
        guard let session else { return nil }
        switch phase {
        case .exercising(let i), .resting(let i):
            return session.exercises.indices.contains(i) ? session.exercises[i] : nil
        default:
            return nil
        }
    }

    var currentExerciseIndex: Int? {
        switch phase {
        case .exercising(let i), .resting(let i): return i
        default: return nil
        }
    }

    var currentProgress: ExerciseProgress? {
        guard let ex = currentExercise else { return nil }
        return progress[ex.id]
    }

    var restRemainingSeconds: Int {
        guard let session else { return 0 }
        // Read `elapsed` (observable, tick-driven) so SwiftUI re-renders every tick.
        // Reading `snapshot()` would only observe accumulated/segmentStart, which don't
        // change between pause/reset and the UI would freeze.
        return max(0, session.restSecondsBetweenExercises - Int(restTimer.elapsed))
    }

    var hasPendingSync: Bool {
        progress.values.contains { $0.syncStatus == .pending }
    }

    var pendingSyncCount: Int {
        progress.values.filter { $0.syncStatus == .pending }.count
    }

    var liveSummary: SessionSummary { makeSummary() }

    /// Called when the user dismisses the summary screen. Returns the VM to the `.ready`
    /// phase with a fresh per-exercise progress map so the Overview is re-startable.
    func acknowledgeCompletion() {
        guard let session else { phase = .idle; return }
        progress = Dictionary(
            uniqueKeysWithValues: session.exercises.map { ($0.id, ExerciseProgress.initial(for: $0.id)) }
        )
        currentSetCount = 0
        exerciseTimer.reset()
        restTimer.reset()
        try? store.clear()
        phase = .ready(session)
    }

    #if DEBUG
    /// Test/preview hook: synchronously seed a ready state from the given session.
    func _seedReady(session: WorkoutSession) {
        self.session = session
        self.progress = Dictionary(
            uniqueKeysWithValues: session.exercises.map { ($0.id, ExerciseProgress.initial(for: $0.id)) }
        )
        self.phase = .ready(session)
    }
    #endif
}
