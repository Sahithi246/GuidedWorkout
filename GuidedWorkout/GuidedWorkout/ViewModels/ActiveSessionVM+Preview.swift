//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

#if DEBUG
import Foundation

extension ActiveSessionVM {
    /// Quick-built VMs for SwiftUI previews. They use the in-memory store and
    /// immediately-succeeding mock service.
    static func previewReady() -> ActiveSessionVM {
        let vm = ActiveSessionVM(
            service: MockWorkoutService(failFetchOnAttempt: nil,
                                         failCompleteExerciseOnCall: nil,
                                         latency: 0...0),
            store: PreviewStore()
        )
        vm.previewSeedReady()
        return vm
    }

    static func previewExercising(index: Int = 0) -> ActiveSessionVM {
        let vm = previewReady()
        vm.startSession()
        for _ in 0..<index { vm.goToNextExercise() }
        return vm
    }

    static func previewResting(nextIndex: Int = 1) -> ActiveSessionVM {
        let vm = previewReady()
        vm.startSession()
        for _ in 0..<max(0, nextIndex - 1) { vm.goToNextExercise() }
        vm.skipExercise()
        return vm
    }

    static func previewSummary() -> ActiveSessionVM {
        let vm = previewReady()
        vm.startSession()
        guard let session = vm.session else { return vm }
        for ex in session.exercises {
            for _ in 0..<ex.sets { vm.completeSet() }
            if case .resting = vm.phase { vm.skipRest() }
        }
        return vm
    }

    func previewSeedReady() {
        _seedReady(session: SeedData.todaySession)
    }
}

private final class PreviewStore: SessionStoreProtocol {
    private var snapshot: SessionSnapshot?
    func load() throws -> SessionSnapshot? { snapshot }
    func save(_ snapshot: SessionSnapshot) throws { self.snapshot = snapshot }
    func clear() throws { snapshot = nil }
}
#endif
