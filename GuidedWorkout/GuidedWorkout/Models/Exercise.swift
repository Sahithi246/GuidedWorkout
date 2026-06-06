//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import Foundation

struct Exercise: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let title: String
    let area: String
    let difficulty: Difficulty
    let target: ExerciseTarget
    let sets: Int
    let safetyNote: String
    let thumbnailURL: URL
    let videoURL: URL
    let instructions: [String]
}
