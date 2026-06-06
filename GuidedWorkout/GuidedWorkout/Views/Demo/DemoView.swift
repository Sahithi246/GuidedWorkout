//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import SwiftUI

struct DemoView: View {

    @Environment(ActiveSessionVM.self) private var vm
    @Environment(\.dismiss) private var dismiss
    let exercise: Exercise

    @State private var appearedStep = -1

    var body: some View {
        let style = exercise.style

        ZStack {
            AppTheme.canvas.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroCard(style: style)
                    titleBlock(style: style)
                    chipRow(style: style)
                    instructionsBlock(style: style)
                    if !exercise.safetyNote.isEmpty {
                        safetyBlock
                    }
                    sourceFooter
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Demo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.canvas, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    vm.exitDemo()
                    dismiss()
                }
                .fontWeight(.semibold)
                .tint(AppTheme.coral)
            }
        }
        .onDisappear { vm.exitDemo() }
        .onAppear {
            appearedStep = -1
            for i in 0..<exercise.instructions.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12 * Double(i + 1)) {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                        appearedStep = max(appearedStep, i)
                    }
                }
            }
        }
    }

    // MARK: - Hero

    private func heroCard(style: ExerciseStyle) -> some View {
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(style.softBackground)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(style.primary.opacity(0.18))
                        .frame(width: 160, height: 160)
                        .offset(x: 50, y: -50)
                        .blur(radius: 24)
                }
                .overlay(alignment: .bottomLeading) {
                    Circle()
                        .fill(style.secondary.opacity(0.18))
                        .frame(width: 120, height: 120)
                        .offset(x: -40, y: 40)
                        .blur(radius: 30)
                }
                .clipped()

            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.6))
                        .frame(width: 92, height: 92)
                    Image(systemName: style.symbolName)
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundStyle(style.gradient)
                }

                HStack(spacing: 4) {
                    Image(systemName: "play.circle.fill").font(.caption2)
                    Text("DEMO PLACEHOLDER")
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(style.primary)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Capsule().fill(.white.opacity(0.7)))
            }
        }
        .frame(height: 220)
        .softShadow(tint: style.primary, opacity: 0.18, radius: 18, y: 10)
    }

    // MARK: - Title

    private func titleBlock(style: ExerciseStyle) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(exercise.title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Text(exercise.area)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(style.primary)
        }
    }

    // MARK: - Chip row

    private func chipRow(style: ExerciseStyle) -> some View {
        HStack(spacing: 8) {
            Chip(text: exercise.difficulty.displayName, systemImage: "gauge.with.dots.needle.50percent", tint: .secondary)
            Chip(text: exercise.target.displayString, systemImage: exercise.target.isTimeBased ? "timer" : "number", tint: style.primary)
            Chip(text: "\(exercise.sets) sets", systemImage: "repeat", tint: .secondary)
        }
    }

    // MARK: - Instructions

    private func instructionsBlock(style: ExerciseStyle) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How to do it")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)

            VStack(spacing: 10) {
                ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { i, step in
                    instructionRow(index: i, text: step, style: style)
                        .opacity(appearedStep >= i ? 1 : 0)
                        .offset(y: appearedStep >= i ? 0 : 16)
                }
            }
        }
    }

    private func instructionRow(index: Int, text: String, style: ExerciseStyle) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle().fill(style.gradient)
                    .softShadow(tint: style.primary, opacity: 0.30, radius: 6, y: 4)
                Text("\(index + 1)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 32, height: 32)

            Text(text)
                .font(.body)
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.black.opacity(0.04), lineWidth: 1)
        )
    }

    // MARK: - Safety

    private var safetyBlock: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.warningTint)

            VStack(alignment: .leading, spacing: 4) {
                Text("Safety")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.warningTint)
                Text(exercise.safetyNote)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.warningTint.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(AppTheme.warningTint.opacity(0.30), lineWidth: 1)
        )
    }

    // MARK: - Source

    private var sourceFooter: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Media is illustrative only", systemImage: "info.circle")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(exercise.videoURL.absoluteString)
                .font(.caption.monospaced())
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.top, 8)
    }
}

#if DEBUG
#Preview("Demo") {
    NavigationStack {
        DemoView(exercise: SeedData.todaySession.exercises[0])
            .environment(ActiveSessionVM.previewExercising(index: 0))
    }
}
#endif
