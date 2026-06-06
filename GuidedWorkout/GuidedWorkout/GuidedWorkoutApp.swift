import SwiftUI

@main
struct GuidedWorkoutApp: App {

    /// Flip to `true` to make the mock service simulate the fetch + save failures called out in
    /// the brief (initial fetch fails once → retry succeeds; second exercise's progress save fails
    /// once → pending banner → retry succeeds). Default is `false` so normal launches load
    /// straight into the workout — flip it on if you want to inspect the failure-handling UI by
    /// hand. The unit tests in `GuidedWorkoutTests` exercise both failure paths regardless of
    /// this toggle.
    private static let demoFailuresEnabled = true

    @State private var vm: ActiveSessionVM = {
        let service = MockWorkoutService(
            failFetchOnAttempt: GuidedWorkoutApp.demoFailuresEnabled ? 1 : nil,
            failCompleteExerciseOnCall: GuidedWorkoutApp.demoFailuresEnabled ? 2 : nil
        )
        let store: SessionStoreProtocol
        do {
            store = try FileSessionStore.defaultStore()
        } catch {
            store = InMemorySessionStore()
        }
        return ActiveSessionVM(service: service, store: store)
    }()

    var body: some Scene {
        WindowGroup {
            RootContainerView(vm: vm)
        }
    }
}

/// Fallback used only if Application Support directory is unavailable (extremely unlikely on iOS).
private final class InMemorySessionStore: SessionStoreProtocol {
    private var snapshot: SessionSnapshot?
    func load() throws -> SessionSnapshot? { snapshot }
    func save(_ snapshot: SessionSnapshot) throws { self.snapshot = snapshot }
    func clear() throws { snapshot = nil }
}
