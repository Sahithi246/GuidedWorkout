//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import SwiftUI

struct RootContainerView: View {

    @State private var vm: ActiveSessionVM
    @State private var path: [Route] = []
    @Environment(\.scenePhase) private var scenePhase

    init(vm: ActiveSessionVM) {
        _vm = State(initialValue: vm)
    }

    var body: some View {
        NavigationStack(path: $path) {
            OverviewView(path: $path)
                .environment(vm)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .active:
                        ActiveSessionContainerView(path: $path)
                            .environment(vm)
                    case .demo(let exercise):
                        DemoView(exercise: exercise)
                            .environment(vm)
                    case .summary:
                        SummaryView(path: $path)
                            .environment(vm)
                    }
                }
        }
        .task {
            await vm.bootstrap()
            // If we restored mid-session, auto-navigate to active screen.
            switch vm.phase {
            case .exercising, .resting:
                if !path.contains(.active) {
                    path.append(.active)
                }
            case .completed:
                if !path.contains(.summary) {
                    path.append(.summary)
                }
            default:
                break
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            vm.handleScenePhase(newPhase)
        }
        .onChange(of: vm.phase) { _, newPhase in
            // Auto-navigate when state machine transitions to completed.
            if case .completed = newPhase, !path.contains(.summary) {
                path.append(.summary)
            }
        }
    }
}
