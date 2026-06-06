//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import Foundation

enum PersistedPhase: Codable, Equatable, Hashable, Sendable {
    case exercising(index: Int)
    case resting(nextIndex: Int)
    case completed

    private enum Kind: String, Codable { case exercising, resting, completed }

    private enum CodingKeys: String, CodingKey {
        case kind
        case index
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
        case .exercising:
            let i = try container.decode(Int.self, forKey: .index)
            self = .exercising(index: i)
        case .resting:
            let i = try container.decode(Int.self, forKey: .index)
            self = .resting(nextIndex: i)
        case .completed:
            self = .completed
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .exercising(let index):
            try container.encode(Kind.exercising, forKey: .kind)
            try container.encode(index, forKey: .index)
        case .resting(let nextIndex):
            try container.encode(Kind.resting, forKey: .kind)
            try container.encode(nextIndex, forKey: .index)
        case .completed:
            try container.encode(Kind.completed, forKey: .kind)
        }
    }
}
