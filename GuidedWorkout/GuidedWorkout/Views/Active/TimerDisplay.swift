//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import SwiftUI

struct TimerDisplay: View {
    let elapsed: TimeInterval
    let target: Int?            // seconds, if time-based
    let isRunning: Bool

    private var displayText: String {
        if let target {
            let remaining = max(0, target - Int(elapsed.rounded(.down)))
            return TimeFormatter.mmss(remaining)
        } else {
            return TimeFormatter.mmss(elapsed)
        }
    }

    private var progress: Double {
        guard let target, target > 0 else { return 0 }
        return min(1, elapsed / TimeInterval(target))
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: 12)
            if target != nil {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: progress)
            }
            VStack(spacing: 4) {
                Text(displayText)
                    .font(.system(size: 64, weight: .semibold, design: .rounded).monospacedDigit())
                Text(isRunning ? "Running" : "Paused")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isRunning ? .green : .orange)
            }
        }
        .frame(width: 240, height: 240)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(target == nil ? "Elapsed time" : "Time remaining")
        .accessibilityValue(displayText)
    }
}

#Preview {
    VStack(spacing: 30) {
        TimerDisplay(elapsed: 12, target: 45, isRunning: true)
        TimerDisplay(elapsed: 18, target: nil, isRunning: false)
    }
}
