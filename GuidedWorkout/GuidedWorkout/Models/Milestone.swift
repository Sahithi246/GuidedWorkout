//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import Foundation

enum Milestone: String, Codable, Equatable, Hashable, Sendable {
    case perfectSession

    var displayName: String {
        switch self {
        case .perfectSession: return "Perfect Session"
        }
    }

    var detail: String {
        switch self {
        case .perfectSession: return "Completed every exercise without skipping a single one."
        }
    }

    var systemImageName: String {
        switch self {
        case .perfectSession: return "rosette"
        }
    }
}
