//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import Foundation

enum SessionPhase: Equatable {
    case idle
    case loading
    case loadFailed(message: String)
    case ready(WorkoutSession)
    case exercising(index: Int)
    case resting(nextIndex: Int)
    case completed(SessionSummary)
}
