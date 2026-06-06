//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import Foundation

protocol WorkoutServiceProtocol: Sendable {
    func fetchTodaySession() async throws -> WorkoutSession
    func saveProgress(_ progress: [ExerciseProgress]) async throws
    func completeExercise(sessionId: String, exerciseId: String, progress: ExerciseProgress) async throws
    func completeSession(_ summary: SessionSummary) async throws
}

enum WorkoutServiceError: LocalizedError, Equatable {
    case simulatedNetworkFailure
    case unknown

    var errorDescription: String? {
        switch self {
        case .simulatedNetworkFailure: return "Network request failed. Please retry."
        case .unknown: return "Something went wrong."
        }
    }
}
