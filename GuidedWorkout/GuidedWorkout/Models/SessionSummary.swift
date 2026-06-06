//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import Foundation

struct SessionSummary: Codable, Equatable, Hashable, Sendable {
    let sessionId: String
    let scheduleId: String
    let workoutId: String
    let completedExerciseCount: Int
    let skippedExerciseCount: Int
    let totalSetsCompleted: Int
    let totalElapsedSeconds: Int
    let milestone: Milestone?
}
