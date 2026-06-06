//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import SwiftUI

struct ActiveSessionContainerView: View {

    @Environment(ActiveSessionVM.self) private var vm
    @Binding var path: [Route]

    var body: some View {
        Group {
            switch vm.phase {
            case .exercising:
                ActiveExerciseView(path: $path)
            case .resting:
                RestView(path: $path)
            case .completed:
                Color.clear  // navigation to summary handled by RootContainerView
            default:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .animation(.snappy(duration: 0.3), value: vm.phase)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(AppTheme.canvas, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    path.removeAll()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Overview")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.coral)
                }
                .accessibilityLabel("Back to overview")
            }

            if case .exercising = vm.phase, let exercise = vm.currentExercise {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vm.enterDemo()
                        path.append(.demo(exercise))
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "play.rectangle")
                            Text("Demo")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.coral)
                    }
                    .accessibilityLabel("View exercise demo")
                }
            }
        }
    }
}
