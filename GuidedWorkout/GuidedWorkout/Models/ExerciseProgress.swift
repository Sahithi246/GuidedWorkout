//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import Foundation

struct ExerciseProgress: Codable, Equatable, Hashable, Sendable {
    let exerciseId: String
    var completedSets: Int
    var skipped: Bool
    var elapsedSeconds: Int
    var syncStatus: SyncStatus

    static func initial(for exerciseId: String) -> ExerciseProgress {
        ExerciseProgress(
            exerciseId: exerciseId,
            completedSets: 0,
            skipped: false,
            elapsedSeconds: 0,
            syncStatus: .synced
        )
    }

    var isUntouched: Bool {
        completedSets == 0 && !skipped && elapsedSeconds == 0
    }
}
