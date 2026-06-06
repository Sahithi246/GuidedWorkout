//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import Testing
import Foundation
@testable import GuidedWorkout

struct ActiveSessionVMTests {

    // MARK: - Helpers

    /// In-memory store keeps tests deterministic and avoids touching real Application Support.
    final class InMemoryStore: SessionStoreProtocol {
        private var snap: SessionSnapshot?
        func load() throws -> SessionSnapshot? { snap }
        func save(_ snapshot: SessionSnapshot) throws { snap = snapshot }
        func clear() throws { snap = nil }
    }

    private func makeVM(
        failFetchOnAttempt: Int? = nil,
        failCompleteExerciseOnCall: Int? = nil
    ) -> (ActiveSessionVM, MockWorkoutService, InMemoryStore) {
        let service = MockWorkoutService(
            failFetchOnAttempt: failFetchOnAttempt,
            failCompleteExerciseOnCall: failCompleteExerciseOnCall,
            latency: 0...0       // remove latency in tests
        )
        let store = InMemoryStore()
        let vm = ActiveSessionVM(service: service, store: store)
        return (vm, service, store)
    }

    private func waitForRemoteSync(_ vm: ActiveSessionVM, expectedCount: Int) async {
        // The VM kicks off a fire-and-forget Task for remote completion. Yield until either the
        // call has been observed (synced or pending) or we exhaust the budget.
        for _ in 0..<50 {
            let observed = vm.progress.values.filter { $0.syncStatus != .synced }.count == 0
            if observed { return }
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }

    // MARK: - Tests

    @Test func loadTodayPopulatesSessionAndReadyPhase() async throws {
        let (vm, _, _) = makeVM()
        await vm.loadToday()
        #expect(vm.session?.id == "session_mobility_001")
        if case .ready = vm.phase { } else { Issue.record("expected .ready") }
    }

    @Test func fetchFailureSurfacesLoadFailed() async throws {
        let (vm, _, _) = makeVM(failFetchOnAttempt: 1)
        await vm.loadToday()
        if case .loadFailed = vm.phase { } else { Issue.record("expected .loadFailed") }
    }

    @Test func retryAfterFetchFailureSucceeds() async throws {
        let (vm, _, _) = makeVM(failFetchOnAttempt: 1)
        await vm.loadToday()           // fails
        await vm.retryLoad()           // succeeds
        if case .ready = vm.phase { } else { Issue.record("expected .ready after retry") }
    }

    @Test func startSessionMovesToExercisingZero() async throws {
        let (vm, _, _) = makeVM()
        await vm.loadToday()
        vm.startSession()
        if case .exercising(let i) = vm.phase { #expect(i == 0) } else { Issue.record("expected .exercising(0)") }
        #expect(vm.currentSetCount == 0)
    }

    @Test func completingAllSetsOfRepExerciseTransitionsToRest() async throws {
        let (vm, _, _) = makeVM()
        await vm.loadToday()
        vm.startSession()
        // Move to glute bridge (index 1, rep-based, 3 sets) by skipping cat-cow
        vm.skipExercise()
        // Cat-cow finish triggers rest; skipRest manually to advance to glute bridge.
        vm.skipRest()
        if case .exercising(let i) = vm.phase { #expect(i == 1) } else { Issue.record("expected .exercising(1)") }

        vm.completeSet()
        #expect(vm.currentSetCount == 1)
        vm.completeSet()
        #expect(vm.currentSetCount == 2)
        vm.completeSet()
        // Now all 3 sets complete — phase transitions to resting before next exercise
        if case .resting = vm.phase { } else { Issue.record("expected .resting after final set") }
    }

    @Test func cannotCompleteMoreSetsThanPrescribed() async throws {
        let (vm, _, _) = makeVM()
        await vm.loadToday()
        vm.startSession()
        vm.skipExercise()
        vm.skipRest()
        // glute bridge, 3 sets
        for _ in 0..<10 { vm.completeSet() }
        // We're now in rest phase, but progress for glute bridge should be exactly 3.
        let p = vm.progress["ex_glute_bridge"]
        #expect(p?.completedSets == 3)
    }

    @Test func skipExerciseMarksSkippedAndAdvances() async throws {
        let (vm, _, _) = makeVM()
        await vm.loadToday()
        vm.startSession()
        let firstId = vm.session!.exercises[0].id
        vm.skipExercise()
        #expect(vm.progress[firstId]?.skipped == true)
        if case .resting(let next) = vm.phase { #expect(next == 1) } else { Issue.record("expected .resting") }
    }

    @Test func skippingEveryExerciseProducesNoMilestone() async throws {
        let (vm, _, _) = makeVM()
        await vm.loadToday()
        vm.startSession()
        for _ in vm.session!.exercises {
            vm.skipExercise()
            if case .resting = vm.phase { vm.skipRest() }
        }
        if case .completed(let summary) = vm.phase {
            #expect(summary.skippedExerciseCount == 5)
            #expect(summary.completedExerciseCount == 0)
            #expect(summary.milestone == nil)
        } else {
            Issue.record("expected .completed")
        }
    }

    @Test func completingAllExercisesAwardsPerfectSession() async throws {
        let (vm, _, _) = makeVM()
        await vm.loadToday()
        vm.startSession()
        guard let session = vm.session else { Issue.record("no session"); return }

        for ex in session.exercises {
            for _ in 0..<ex.sets { vm.completeSet() }
            // After last set, exercise auto-transitions. If rest, skip it.
            if case .resting = vm.phase { vm.skipRest() }
        }

        if case .completed(let summary) = vm.phase {
            #expect(summary.completedExerciseCount == session.exercises.count)
            #expect(summary.skippedExerciseCount == 0)
            #expect(summary.milestone == .perfectSession)
            #expect(summary.totalSetsCompleted == session.exercises.reduce(0) { $0 + $1.sets })
        } else {
            Issue.record("expected .completed")
        }
    }

    @Test func saveFailureMarksProgressPending() async throws {
        // Fail on the FIRST completeExercise call.
        let (vm, _, _) = makeVM(failCompleteExerciseOnCall: 1)
        await vm.loadToday()
        vm.startSession()
        let firstId = vm.session!.exercises[0].id

        vm.skipExercise()
        // Yield briefly so the fire-and-forget remote call has a chance to fail.
        try? await Task.sleep(nanoseconds: 50_000_000)
        #expect(vm.progress[firstId]?.syncStatus == .pending)
        #expect(vm.hasPendingSync)
    }

    @Test func retryPendingSyncRecoversToSynced() async throws {
        // Fail on call #1, succeed on retry.
        let (vm, _, _) = makeVM(failCompleteExerciseOnCall: 1)
        await vm.loadToday()
        vm.startSession()
        let firstId = vm.session!.exercises[0].id

        vm.skipExercise()
        try? await Task.sleep(nanoseconds: 50_000_000)
        #expect(vm.progress[firstId]?.syncStatus == .pending)

        await vm.retryPendingSync()
        #expect(vm.progress[firstId]?.syncStatus == .synced)
        #expect(vm.hasPendingSync == false)
    }

    @Test func snapshotIsPersistedAfterSetCompletion() async throws {
        let (vm, _, store) = makeVM()
        await vm.loadToday()
        vm.startSession()
        vm.skipExercise()
        let saved = try #require(try store.load())
        if case .resting(let nextIndex) = saved.phase {
            #expect(nextIndex == 1)
        } else {
            Issue.record("expected resting in persisted snapshot")
        }
    }

    @Test func snapshotClearedAfterCompletion() async throws {
        let (vm, _, store) = makeVM()
        await vm.loadToday()
        vm.startSession()
        // Skip everything to reach completion fast
        while true {
            switch vm.phase {
            case .exercising:
                vm.skipExercise()
            case .resting:
                vm.skipRest()
            case .completed:
                #expect(try store.load() == nil)
                return
            default:
                Issue.record("unexpected phase \(vm.phase)")
                return
            }
        }
    }
}
