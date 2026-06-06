//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import SwiftUI

struct PendingSyncBanner: View {
    let count: Int
    let isRetrying: Bool
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "icloud.slash")
                .font(.title3)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(count) exercise\(count == 1 ? "" : "s") not synced")
                    .font(.subheadline.weight(.semibold))
                Text("Your progress is saved locally.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: onRetry) {
                if isRetrying {
                    ProgressView().controlSize(.small)
                } else {
                    Text("Retry")
                        .font(.subheadline.weight(.semibold))
                }
            }
            .buttonStyle(.bordered)
            .tint(.orange)
            .disabled(isRetrying)
            .accessibilityLabel(isRetrying ? "Retrying sync" : "Retry sync")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.orange.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    PendingSyncBanner(count: 2, isRetrying: false, onRetry: {})
        .padding()
}
