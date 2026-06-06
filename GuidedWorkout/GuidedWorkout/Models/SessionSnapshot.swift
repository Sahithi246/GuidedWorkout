//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import Foundation

struct SessionSnapshot: Codable, Equatable, Sendable {
    let session: WorkoutSession
    var progress: [ExerciseProgress]
    var phase: PersistedPhase
    var elapsedOnCurrent: Int
    var restRemainingSeconds: Int?
    let startedAt: Date
    var lastUpdatedAt: Date
}
