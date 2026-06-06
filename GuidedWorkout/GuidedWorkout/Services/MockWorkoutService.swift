//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import Foundation

actor MockWorkoutService: WorkoutServiceProtocol {

    private var fetchAttemptCount = 0
    private var completeExerciseCallCount = 0
    private var saveProgressCallCount = 0

    private let failFetchOnAttempt: Int?
    private let failCompleteExerciseOnCall: Int?
    private let failSaveProgressOnCall: Int?
    private let latency: ClosedRange<UInt64>
    private let session: WorkoutSession

    init(
        session: WorkoutSession = SeedData.todaySession,
        failFetchOnAttempt: Int? = 1,
        failCompleteExerciseOnCall: Int? = 2,
        failSaveProgressOnCall: Int? = nil,
        latency: ClosedRange<UInt64> = 300_000_000...700_000_000
    ) {
        self.session = session
        self.failFetchOnAttempt = failFetchOnAttempt
        self.failCompleteExerciseOnCall = failCompleteExerciseOnCall
        self.failSaveProgressOnCall = failSaveProgressOnCall
        self.latency = latency
    }

    func resetFailureFlags() {
        fetchAttemptCount = 0
        completeExerciseCallCount = 0
        saveProgressCallCount = 0
    }

    private func simulateLatency() async {
        let nanos = UInt64.random(in: latency)
        try? await Task.sleep(nanoseconds: nanos)
    }

    func fetchTodaySession() async throws -> WorkoutSession {
        await simulateLatency()
        fetchAttemptCount += 1
        if let failOn = failFetchOnAttempt, fetchAttemptCount == failOn {
            throw WorkoutServiceError.simulatedNetworkFailure
        }
        return session
    }

    func saveProgress(_ progress: [ExerciseProgress]) async throws {
        await simulateLatency()
        saveProgressCallCount += 1
        if let failOn = failSaveProgressOnCall, saveProgressCallCount == failOn {
            throw WorkoutServiceError.simulatedNetworkFailure
        }
    }

    func completeExercise(sessionId: String, exerciseId: String, progress: ExerciseProgress) async throws {
        await simulateLatency()
        completeExerciseCallCount += 1
        if let failOn = failCompleteExerciseOnCall, completeExerciseCallCount == failOn {
            throw WorkoutServiceError.simulatedNetworkFailure
        }
    }

    func completeSession(_ summary: SessionSummary) async throws {
        await simulateLatency()
    }
}
