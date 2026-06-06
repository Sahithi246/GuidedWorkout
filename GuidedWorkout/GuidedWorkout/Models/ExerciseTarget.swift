//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import Foundation

enum ExerciseTarget: Codable, Equatable, Hashable, Sendable {
    case time(seconds: Int)
    case reps(count: Int)

    var isTimeBased: Bool {
        if case .time = self { return true }
        return false
    }

    var isRepBased: Bool {
        if case .reps = self { return true }
        return false
    }

    var displayString: String {
        switch self {
        case .time(let seconds): return "\(seconds) sec"
        case .reps(let count): return "\(count) reps"
        }
    }

    private enum Kind: String, Codable { case time, reps }

    private enum CodingKeys: String, CodingKey {
        case kind
        case value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        let value = try container.decode(Int.self, forKey: .value)
        switch kind {
        case .time: self = .time(seconds: value)
        case .reps: self = .reps(count: value)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .time(let seconds):
            try container.encode(Kind.time, forKey: .kind)
            try container.encode(seconds, forKey: .value)
        case .reps(let count):
            try container.encode(Kind.reps, forKey: .kind)
            try container.encode(count, forKey: .value)
        }
    }
}
