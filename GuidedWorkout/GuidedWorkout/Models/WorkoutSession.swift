//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import Foundation

struct WorkoutSession: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let scheduleId: String
    let workoutId: String
    let title: String
    let subtitle: String
    let estimatedMinutes: Int
    let restSecondsBetweenExercises: Int
    let exercises: [Exercise]
}
