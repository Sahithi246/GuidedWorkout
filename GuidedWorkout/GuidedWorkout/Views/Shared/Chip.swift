//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import SwiftUI

/// A small pill chip used in headers and meta rows.
struct Chip: View {
    let text: String
    var systemImage: String? = nil
    var tint: Color = AppTheme.coral

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage).font(.caption2.weight(.semibold))
            }
            Text(text).font(.caption.weight(.semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(tint.opacity(0.14))
        )
    }
}

#Preview {
    HStack {
        Chip(text: "Beginner", systemImage: "gauge.with.dots.needle.50percent")
        Chip(text: "45 sec", systemImage: "timer", tint: AppTheme.mint)
        Chip(text: "Spine", systemImage: "figure.flexibility", tint: AppTheme.lavender)
    }
    .padding()
}
