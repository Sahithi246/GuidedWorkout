# GuidedWorkout

A standalone SwiftUI guided workout experience for a wellness app. Loads today's
prescribed routine, walks the user through each exercise (rep or time based),
times rests, surfaces a per-exercise demo, and produces a session summary —
with offline-first persistence and pending-sync recovery.

Built as a take-home for native iOS feature delivery: MVVM + `@Observable`,
async/await service boundaries, wall-clock timers, local-first writes, and
a reasoned design system.

## Highlights

- **MVVM with `@Observable`** — single `ActiveSessionVM` owns the state machine
  and is the canonical truth for every screen.
- **Wall-clock timer** — `accumulated + (now − segmentStart)` math means the
  timer stays correct across backgrounding, lock-screen, or app kill — no
  catch-up logic needed.
- **Local-first sync** — every meaningful state transition writes a snapshot
  to `Application Support` before any remote attempt. If a save fails the
  progress stays `.pending` locally and the user can retry from the UI.
- **Resumable** — kill the app mid-set; relaunch lands you exactly where you
  were, timer paused at the right elapsed value. Rest snapshots even account
  for wall-clock time that passed while the app was suspended.
- **Disciplined design** — one brand color (coral) + neutrals + semantic
  accents only. Patterned after Strava / Apple Fitness+ — variety from icons
  and typography, not from per-exercise hue.
- **Protocol-driven boundaries** — `WorkoutServiceProtocol` and
  `SessionStoreProtocol` keep the VM testable. The mock service simulates the
  fetch + save failures called out in the brief.
- **24 unit tests** across timer math, state machine, persistence round-trip,
  and pending-sync recovery — all green.

## Quick start

```sh
open GuidedWorkout/GuidedWorkout.xcodeproj
```

Then in Xcode:

1. Pick the `GuidedWorkout` scheme.
2. Pick any iOS 26 simulator (e.g. iPhone 17 Pro).
3. **⌘R** to run, **⌘U** to run tests.

Requirements: **Xcode 16+** and the **iOS 26 SDK**. Deployment target is iOS 26.2.

To see the simulated fetch / save failures (off by default), flip
`demoFailuresEnabled = true` in `GuidedWorkoutApp.swift` and rebuild. The unit
tests cover both failure paths regardless of the toggle.

## Project layout

```
GuidedWorkout/                       ← repo root
├── README.md                        (this file)
├── NOTES.md                         architecture, HLD/LLD, assumptions, tradeoffs
└── GuidedWorkout/                   ← Xcode project root
    ├── GuidedWorkout.xcodeproj
    ├── GuidedWorkout/
    │   ├── App/                     RootContainerView, Route, app entry
    │   ├── Models/                  Codable value types
    │   ├── Services/                WorkoutServiceProtocol + MockWorkoutService
    │   ├── Persistence/             SessionStoreProtocol + FileSessionStore
    │   ├── Timer/                   WorkoutTimer (wall-clock based)
    │   ├── ViewModels/              ActiveSessionVM, SessionPhase
    │   ├── Theme/                   AppTheme palette, ExerciseStyle
    │   ├── Views/                   Overview, Active, Rest, Demo, Summary, Shared
    │   ├── Mocks/                   SeedData (5 exercises from the brief)
    │   └── GuidedWorkoutApp.swift   @main, DI wiring
    └── GuidedWorkoutTests/          Swift Testing suites (24 tests)
```

## Tech stack

| Layer | Choice |
|---|---|
| UI | SwiftUI, iOS 26 |
| Observation | `@Observable` macro (iOS 17+) |
| Concurrency | Swift `async`/`await`, `actor` for the mock service |
| Persistence | `FileManager` + `Codable` JSON in Application Support |
| Navigation | `NavigationStack(path:)` driven by an enum `Route` |
| Tests | Swift Testing (`import Testing`) |
| Architecture | MVVM with protocol-bounded service and store |

## Where to go next

- **[NOTES.md](./NOTES.md)** — the take-home companion: assumptions, HLD/LLD
  walkthrough, timer correctness derivation, lifecycle decisions, tradeoffs,
  test coverage map, and a "given more time" list.
- **`GuidedWorkout/GuidedWorkoutTests/`** — read these for a quick understanding
  of the behavior the VM guarantees (totals, milestone rule, sync transitions,
  snapshot round-trips, timer wall-clock math).
