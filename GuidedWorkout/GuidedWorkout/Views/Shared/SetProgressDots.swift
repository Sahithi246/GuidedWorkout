//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import SwiftUI

struct SetProgressDots: View {
    let completed: Int
    let total: Int
    /// 1-indexed. The dot at this position is shown as "current/in-progress".
    /// Pass `nil` to hide the current-state styling (e.g. on the summary screen).
    var current: Int? = nil
    var size: CGFloat = 16
    var spacing: CGFloat = 12

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<max(total, 0), id: \.self) { i in
                dot(at: i + 1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sets completed: \(completed) of \(total)")
    }

    @ViewBuilder
    private func dot(at setNumber: Int) -> some View {
        if setNumber <= completed {
            // Done
            Circle()
                .fill(AppTheme.coral)
                .frame(width: size, height: size)
                .transition(.scale)
        } else if let current, setNumber == current {
            // Current
            ZStack {
                Circle()
                    .fill(AppTheme.coral.opacity(0.18))
                Circle()
                    .strokeBorder(AppTheme.coral, lineWidth: 2.5)
            }
            .frame(width: size + 4, height: size + 4)
        } else {
            // Upcoming
            Circle()
                .fill(Color.secondary.opacity(0.22))
                .frame(width: size, height: size)
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        SetProgressDots(completed: 0, total: 3, current: 1)
        SetProgressDots(completed: 1, total: 3, current: 2)
        SetProgressDots(completed: 3, total: 3)
    }
    .padding()
}
#endif
