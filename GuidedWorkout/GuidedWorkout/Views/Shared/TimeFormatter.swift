//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import Foundation

enum TimeFormatter {
    static func mmss(_ totalSeconds: Int) -> String {
        let s = max(0, totalSeconds)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    static func mmss(_ totalSeconds: TimeInterval) -> String {
        mmss(Int(totalSeconds.rounded(.down)))
    }
}
