# GuidedWorkout — Implementation Notes

Take-home companion document. Covers assumptions, run steps, **HLD**, **LLD**,
key correctness decisions, tradeoffs, and what I'd add given more time.

For the quick "what is this and how do I run it" overview, see
[README.md](./README.md).

---

## 1. Run steps

1. Open `GuidedWorkout/GuidedWorkout.xcodeproj` in **Xcode 16+**.
2. Select the `GuidedWorkout` scheme.
3. Pick any iOS 26 simulator (e.g. iPhone 17 Pro).
4. **⌘R** to run, **⌘U** to run the unit tests.

Deployment target is iOS 26.2 (the project default that came with Xcode 16).

### Demo failure switch

The bundled mock service supports the two failures the brief calls out:

- One simulated initial fetch failure (recovers on retry)
- One simulated progress-save failure on the second exercise (stays `.pending`
  until you tap **Retry** on the banner)

**These failures are off by default** to keep iteration smooth. Flip
`demoFailuresEnabled = true` at the top of `GuidedWorkoutApp.swift` and
rebuild to inspect the failure-handling UI by hand. The unit tests in
`GuidedWorkoutTests/` exercise both paths (and their successful retries)
regardless of the toggle:
- `fetchFailureSurfacesLoadFailed`
- `retryAfterFetchFailureSucceeds`
- `saveFailureMarksProgressPending`
- `retryPendingSyncRecoversToSynced`

---

## 2. Assumptions

Things the brief left open that I committed to:

| Topic | Assumption |
|---|---|
| **Minimum iOS** | iOS 26 deployment target. The project was created in Xcode 16 with that default. I went with `@Observable` (iOS 17+) rather than `ObservableObject`. |
| **Active-timer background behavior** | Auto-pause on background. Safer than silently consuming a set when the user puts the phone down. Resume requires an explicit tap. |
| **Rest-timer background behavior** | Keep counting on wall-clock. The snapshot's `lastUpdatedAt` lets us account for time that passed while the app was suspended or killed — if the rest period has expired by the time the app comes back, we advance straight to the next exercise. |
| **Milestone rule** | `.perfectSession` if every exercise is fully completed and none is skipped. Simple, testable, satisfying. |
| **Rep flow** | Tap "Complete Set" once per set. No auto-rest between sets within an exercise. The only rest is between exercises (the brief's `rest_seconds_between_exercises`). |
| **Time-based set advancement** | Auto-completes when the timer reaches the target seconds. After the last set, the exercise finishes and rest begins. |
| **Previous / Forward semantics** | "Skip" is the state-changing button. "Forward" during rest means "skip rest". The exercise screen does not expose pure-navigation Previous/Next because that turned out to be confusing — see the early user feedback referenced in §9. |
| **Acknowledging summary** | Tapping **Done** transitions the VM back to `.ready` (snapshot cleared, progress reset), so the user returns to a clean Overview. |
| **Color discipline** | One brand color (coral) + neutrals + semantic accents. Patterned after Strava / Apple Fitness+. Per-area body identity comes from SF Symbols, not surface tints. |

---

## 3. High-Level Design (HLD)

### 3.1 Layered architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│ View layer (SwiftUI)                                                   │
│ ─ Overview, Active, Rest, Demo, Summary, Shared widgets                │
│                                  ▲ observes properties                 │
│                                  │                                     │
├──────────────────────────────────┼─────────────────────────────────────┤
│ ViewModel layer                  │                                     │
│ ─ ActiveSessionVM (@Observable)  │  single source of truth             │
│    ├ SessionPhase state machine   │                                     │
│    ├ WorkoutTimer × 2 (exercise + rest)                                │
│    └ orchestrates save/sync/persistence                                │
│           │                          │                                 │
│           │ async                    │ sync                            │
│           ▼                          ▼                                 │
├──────────────────────────────┬─────────────────────────────────────────┤
│ Service boundary             │ Persistence boundary                    │
│ ─ WorkoutServiceProtocol     │ ─ SessionStoreProtocol                  │
│ ─ MockWorkoutService (actor) │ ─ FileSessionStore (JSON + FileManager) │
├──────────────────────────────┴─────────────────────────────────────────┤
│ Model layer (Codable, Sendable value types)                            │
│ ─ WorkoutSession, Exercise, ExerciseProgress, SessionSummary,          │
│   SessionSnapshot, Milestone, SyncStatus, PersistedPhase, …            │
└────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Design rules

- **Models are pure values.** No logic on them beyond display formatters and
  `Codable`. Equatable + Sendable everywhere.
- **VM is the only place state mutates.** Every transition flows through a
  method on `ActiveSessionVM`. Derived totals (counts, sums) are computed
  properties — never tracked as parallel state. Eliminates a whole class of
  drift bugs.
- **Service and store are protocols.** The VM only sees the protocols.
  Production wires `MockWorkoutService` and `FileSessionStore`; tests wire
  in-memory and zero-latency variants of the same protocols.
- **One VM, one NavigationStack path.** The VM lives at the root container.
  Demo and Summary are pushed onto the stack — they cannot deallocate the VM
  by popping. Kills the "demo navigation resets the active session" red flag.
- **Local-first writes.** Every meaningful transition persists the snapshot
  *before* attempting any remote call. The user's work never lives only on the
  network's word.
- **Wall-clock timer.** The `Foundation.Timer` ticker is only a UI repaint
  trigger; truth is Date arithmetic. Backgrounding, lock screen, and app kill
  are all the same to the timer.

### 3.3 State machine

The VM exposes one observable enum that every screen reads:

```
        ┌──────┐
        │ idle │
        └──┬───┘
           │ .task → bootstrap()
           ▼
       ┌─────────┐         throw
       │ loading │──────────────────────► loadFailed(message)
       └────┬────┘                              │
            │ success                           │ retryLoad()
            ▼                                   ▼
        ┌────────────┐ ◄───────────────────── (loops back via loadToday)
        │   ready    │
        └─────┬──────┘
              │ startSession()
              ▼
       ┌──────────────┐  complete set / skip   ┌──────────────┐
       │ exercising(i)│ ─────────────────────► │  resting(i+1)│
       └──────┬───────┘                        └──────┬───────┘
              │ (after last exercise)                 │  rest expired
              │                                       │  or skipRest()
              ▼                                       ▼
        ┌─────────────┐                       ┌──────────────┐
        │ completed(s)│ ◄─── completeSession ─┤ exercising(i)│
        └─────────────┘                       └──────────────┘
```

### 3.4 Navigation

`NavigationStack(path: [Route])` rooted at Overview.

```
Overview
  ├─ push  → ActiveSessionContainer   (renders Active / Rest based on phase)
  │            └─ push → Demo
  └─ push  → Summary  (auto-pushed when phase = .completed)
```

The VM is held by `RootContainerView` as a `@State` and provided to children
via `.environment(vm)`. Pushing/popping changes nothing about the VM's lifetime.

---

## 4. Low-Level Design (LLD)

### 4.1 Models (Models/)

| Type | Purpose | Notes |
|---|---|---|
| `WorkoutSession` | Top-level session data | Mirrors brief's JSON; `exercises: [Exercise]` is embedded for natural containment |
| `Exercise` | One exercise definition | Brief's `type` + `target` collapsed into one `ExerciseTarget` enum (declared adjustment — see §9) |
| `ExerciseTarget` | `.time(seconds: Int)` / `.reps(count: Int)` | Type-safe sum type; pattern-matched in views and VM |
| `Difficulty` | `.beginner` / `.intermediate` / `.advanced` | String-backed enum |
| `ExerciseProgress` | Per-exercise progress record | Matches brief exactly: `exerciseId`, `completedSets`, `skipped`, `elapsedSeconds`, `syncStatus` |
| `SyncStatus` | `.synced` / `.pending` / `.failed` | `.failed` defined but currently unused (mild over-engineering) |
| `SessionSummary` | Final session totals | Matches brief; `milestone: Milestone?` is the optional value |
| `Milestone` | `.perfectSession` (today; extensible) | Carries display name, detail, SF Symbol |
| `SessionSnapshot` | Persistence wrapper | `{ session, progress[], phase, elapsedOnCurrent, restRemainingSeconds?, startedAt, lastUpdatedAt }` |
| `PersistedPhase` | Disk-side phase enum | `.exercising(i)` / `.resting(i)` / `.completed` — narrower than runtime SessionPhase (excludes transient states like .loading) |

### 4.2 Service layer (Services/)

`WorkoutServiceProtocol` (matches the brief verbatim, all Sendable):
```swift
func fetchTodaySession() async throws -> WorkoutSession
func saveProgress(_ progress: [ExerciseProgress]) async throws
func completeExercise(sessionId: String, exerciseId: String,
                      progress: ExerciseProgress) async throws
func completeSession(_ summary: SessionSummary) async throws
```

`MockWorkoutService` (actor):
- Configurable `failFetchOnAttempt: Int?`, `failCompleteExerciseOnCall: Int?`,
  `failSaveProgressOnCall: Int?`. `nil` disables that failure.
- Default config in production app (when `demoFailuresEnabled = true`): fetch
  fails on attempt 1, completeExercise fails on call 2.
- Latency `300–700ms` per call via `Task.sleep` so the loading states are
  visible. Tests pass `latency: 0...0` to skip the wait.
- `actor` isolation = the call counters are race-free.
- `resetFailureFlags()` lets tests reset between scenarios.

### 4.3 Persistence layer (Persistence/)

`SessionStoreProtocol` (Sendable):
```swift
func load() throws -> SessionSnapshot?
func save(_ snapshot: SessionSnapshot) throws
func clear() throws
```

`FileSessionStore`:
- Single JSON file at
  `Application Support/GuidedWorkout/session_snapshot.json`.
- Atomic writes (`Data.write(to:, options: .atomic)`).
- JSON dates encoded as ISO 8601 for human-readability while debugging.
- Pretty-printed + sorted keys for the same reason.
- `nonisolated final class` — runs synchronously off the VM call site; payload
  is tiny (few KB) so blocking briefly is acceptable.

### 4.4 `WorkoutTimer` (Timer/)

The single most lifecycle-sensitive component. Two instances live on the VM:
one for the active exercise, one for rest.

State:
- `accumulated: TimeInterval` — completed (paused) segments
- `segmentStart: Date?` — start of current running segment (nil when paused)
- `elapsed: TimeInterval` — observable for the view ticker
- `ticker: Foundation.Timer?` — fires every 100ms purely to call `refresh()`
  which sets `elapsed = snapshot()`

Canonical reading:
```swift
func snapshot() -> TimeInterval {
    guard let start = segmentStart else { return accumulated }
    return accumulated + clock().timeIntervalSince(start)
}
```

API:
- `start()` — records segmentStart = clock(), starts ticker
- `pause()` — folds `now − segmentStart` into accumulated, clears segmentStart
- `resume()` — alias for start
- `reset()` — clears everything
- `seed(elapsed:)` — restore from a persisted snapshot in paused state
- `clock: () -> Date` — injectable for tests (default `{ Date() }`)

### 4.5 `ActiveSessionVM` (ViewModels/)

Owned state (`@Observable`):
- `phase: SessionPhase`
- `session: WorkoutSession?`
- `progress: [String: ExerciseProgress]` keyed by exerciseId
- `currentSetCount: Int`
- `isRetryingSync: Bool`
- `exerciseTimer`, `restTimer` — child observables

Private:
- `autoCompleteTask`, `restCompleteTask` — Tasks that fire transitions when
  the wall-clock reaches a target. Cancellable.
- `exerciseWasRunningBeforeDemo` — used by enter/exitDemo for resume.

Key methods grouped by purpose:

| Group | Methods |
|---|---|
| Bootstrap | `bootstrap()`, `loadToday()`, `retryLoad()`, `discardSnapshotAndStartFresh()` |
| Session control | `startSession()`, `resumeExerciseTimer()`, `pauseExerciseTimer()` |
| Set / exercise mutation | `completeSet()`, `skipExercise()`, `goToPreviousExercise()`, `goToNextExercise()` |
| Rest | `skipRest()` |
| Sync | `attemptRemoteCompleteExercise(forIndex:)` (private), `retryPendingSync()` |
| Demo | `enterDemo()`, `exitDemo()` |
| Lifecycle | `handleScenePhase(_:)` |
| Summary | `liveSummary` (derived), `acknowledgeCompletion()` |
| Persistence | `restore(from:)` (private), `persistSnapshot()` (private) |

### 4.6 View hierarchy (Views/)

```
RootContainerView                 owns the VM, hosts NavigationStack
└─ OverviewView                   hero card + horizontal carousel
    ├─ ExerciseCarouselCard       tap → opens Demo for that exercise
    └─ PendingSyncBanner          (when any progress is pending)
└─ ActiveSessionContainerView     swaps Active / Rest based on vm.phase
    ├─ ActiveExerciseView         ribbon, ring/rep display, set dots, actions
    │   ├─ SessionRibbon
    │   ├─ GradientTimerRing
    │   ├─ RepCounterRing
    │   ├─ SetProgressDots
    │   └─ UpNextPeek
    └─ RestView                   countdown ring + "up next" hero card
└─ DemoView                       hero card + chip row + animated step cards
└─ SummaryView                    celebration hero + stat tiles + per-exercise carousel
```

Shared widgets in `Views/Shared/`: `Chip`, `Haptics`, `PendingSyncBanner`,
`PrimaryButtonStyle`, `SecondaryButtonStyle`, `SetProgressDots`,
`TimeFormatter`.

### 4.7 Theme (Theme/)

`AppTheme` — palette tokens (coral, peach, mint, teal, lavender, warning,
success), canvas/surface, brand gradient, soft shadow modifier.

`ExerciseStyle` — per-exercise visual identity. Today every exercise uses the
brand coral; variety comes from per-area **SF Symbols** (`figure.flexibility`,
`figure.strengthtraining.functional`, `figure.core.training`, `figure.walk`,
`figure.rower`). This is deliberate — see §9 on color discipline.

### 4.8 Critical algorithms

**Wall-clock restore that survives suspension** (`ActiveSessionVM.restore(from:)`):
```swift
case .resting(let nextIndex):
    let total = TimeInterval(snapshot.session.restSecondsBetweenExercises)
    let savedRemaining = TimeInterval(snapshot.restRemainingSeconds ?? total)
    let secondsSinceLastSave = Date().timeIntervalSince(snapshot.lastUpdatedAt)
    let actualRemaining = max(0, savedRemaining - secondsSinceLastSave)
    if actualRemaining <= 0 {
        moveTo(exerciseIndex: nextIndex)              // rest already expired
    } else {
        restTimer.seed(elapsed: total - actualRemaining)
        restTimer.start()
        scheduleRestCompletion()
    }
```
This is what makes "killed mid-rest, relaunched 60 s later" do the right
thing instead of resuming the rest at the saved position.

**Local-first save coordination** (`attemptRemoteCompleteExercise`):
```swift
p.syncStatus = .pending
progress[exId] = p
persistSnapshot()                                  // disk first
do {
    try await service.completeExercise(...)
    p.syncStatus = .synced
    progress[exId] = p
    persistSnapshot()
} catch {
    // stays .pending — banner appears, retry available
}
```
The disk write happens *before* the network attempt. Crash between the two
and the user's work is preserved with the correct `.pending` status.

**Set count guard** (`completeSet`):
```swift
guard case .exercising = phase, let session, let ex = currentExercise else { return }
guard currentSetCount < ex.sets else { return }    // impossible-state guard
currentSetCount += 1
```
Eliminates the "more sets than prescribed" red flag at the source.

---

## 5. Timer correctness in depth

The active timer is the highest-risk piece of code per the brief
(timer drift across backgrounding is the #1 red flag). Approach:

- The `Foundation.Timer` is **only** a UI repaint trigger. It calls
  `refresh()` ~10 times per second; `refresh()` sets `elapsed = snapshot()`.
- `snapshot()` is a pure function of `accumulated + (now − segmentStart)`.
- Pause folds the current segment into `accumulated`; resume re-sets
  `segmentStart = now`.
- Returning from background: the next `refresh()` evaluates against the
  current `Date()`, so elapsed jumps forward by exactly the time that passed.
  No catch-up logic, no per-tick drift.

For unit tests, the `clock: () -> Date` closure is injectable:
```swift
var fakeNow = Date(timeIntervalSince1970: 0)
timer.clock = { fakeNow }
timer.start()
fakeNow = fakeNow.addingTimeInterval(120)   // simulate 2 min of background
#expect(timer.snapshot() == 120)
```
That's the `snapshotIsCorrectAcrossSimulatedBackgrounding` test.

---

## 6. Lifecycle behavior

- **Active exercise + background → auto-pause** the exercise timer, persist
  snapshot. Resume requires an explicit Resume tap on return.
- **Rest + background → keep counting** (wall-clock). On return we re-check;
  if rest already expired we advance to the next exercise. The snapshot
  remembers `lastUpdatedAt` so a cold launch still computes the right
  remaining time.
- **App killed mid-exercise → relaunch resumes paused** at the saved elapsed.
- **App killed mid-rest → relaunch computes `now − lastUpdatedAt` against
  saved remaining**, then either advances immediately or restarts the
  countdown with the corrected remaining.

`handleScenePhase(_:)` on the VM owns the scene-aware logic; the view layer
just forwards `@Environment(\.scenePhase)` changes into it.

---

## 7. Local-first persistence

Single snapshot file under
`Application Support/GuidedWorkout/session_snapshot.json`, written atomically
on every meaningful transition:
- exercise advanced / skipped
- set completed
- paused / resumed
- rest started / skipped
- sync status changed
- demo entered / exited

Cleared on session completion (`completeSession()`).

Snapshot is loaded in `bootstrap()` on app launch. If present, the VM is
seeded into the right phase and auto-navigates to the Active or Summary
screen via `RootContainerView`'s `.onChange(of: vm.phase)`.

---

## 8. Pending sync flow

```
completeSet (last set) or skipExercise
        │
        ▼
  finishCurrentExercise
        │
        ▼  (fire-and-forget Task)
  attemptRemoteCompleteExercise
        │
        ▼  step 1: mark .pending locally + persist
        ▼  step 2: try await service.completeExercise(...)
        │
   success │ failure
   ────────┼────────
   step 3: │ stays .pending
   flip to │ banner appears
   .synced │
   persist │ user taps Retry
           ▼
       retryPendingSync() walks .pending entries
       and re-attempts (next call # → no throw → .synced)
```

The pending banner is wired in two places (Overview and Summary) so the user
can retry whenever they next see the UI.

---

## 9. Decisions and tradeoffs

| Topic | Decision | Why |
|---|---|---|
| Observation | `@Observable` (iOS 17+) | Modern Apple guidance, finer-grained view updates than `ObservableObject`. Deployment target is iOS 26.2. |
| Persistence backend | JSON via `FileManager` | Tiny payload (~few KB); avoids SwiftData / Core Data ceremony for a single-snapshot use case. |
| Timer counting model | Wall-clock with injectable clock | The brief flags timer/background drift as a red flag; this is the simplest robust approach. |
| Active timer on background | Auto-pause | Confirmed up front. Safer than silently consuming time when the phone is pocketed. |
| Rest timer on background | Keep counting (wall-clock) | Rest doesn't need user attention; auto-pausing it would feel broken when you return. |
| Rep flow | Manual "Complete Set" per set, no auto-rest between sets within an exercise | Matches the brief literally; the only rest is between exercises. |
| Time-based set advancement | Auto-completes when the timer reaches target | Implied by "Set completion when timer reaches target". |
| Milestone rule | `.perfectSession` if every exercise fully completed and none skipped | Simple, testable, satisfying. |
| Forward / Previous on Active screen | **Removed** the pure-navigation buttons | First UX iteration had both Skip (state-changing) and Next (navigation-only), which users tapped interchangeably. The summary showed 0 skipped after the user "skipped" 3 via Next. Now Skip is the only way to advance from an exercise without completing it. |
| Color discipline | One brand coral + neutrals + semantic accents | First pass had 5 per-area colorways. Pulled back to Strava / Apple Fitness+ pattern: variety from icons and typography, not surface hue. |
| Demo navigation | Push onto NavigationStack with VM held at root | Prevents the "demo navigation resets the active session" red flag. |
| Test runner | Swift Testing (`import Testing`) | Native to Xcode 16+, cleaner than XCTest. Same target as the app via `@testable import`. |
| Demo failures | Off by default, gated behind `demoFailuresEnabled` toggle | The mock retains the capability; flipping the boolean wires it in for live demo. Tests cover both paths regardless. |
| `ExerciseTarget` shape | Sum type `.time(seconds:)` / `.reps(count:)` | Spec has `type` + `target` strings (`"45 sec"`) which require parsing and can be mis-paired. Sum type is type-safe and the brief allows the adjustment. |

---

## 10. Test coverage

24 tests across 3 suites, all green. Run with **⌘U** in Xcode or:
```sh
xcodebuild -project GuidedWorkout.xcodeproj -scheme GuidedWorkout \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

| Suite | Validates |
|---|---|
| `WorkoutTimerTests` | snapshot zero before start, advancement with injected clock, pause accumulates, reset, seed-then-resume, **wall-clock survives simulated backgrounding** |
| `SessionStoreTests` | load returns nil when missing, save/load round-trip equality, clear removes file, clear-on-missing is safe, resting-phase snapshot preserved |
| `ActiveSessionVMTests` | loadToday phase transition, fetch-failure phase, retry-after-fetch-failure, startSession → exercising(0), rep-based last-set transitions to rest, **cannot complete more sets than prescribed**, skip marks skipped and advances, all-skipped produces no milestone, **all-completed awards `.perfectSession`**, save failure → `.pending`, retryPendingSync → `.synced`, snapshot persisted after set, snapshot cleared after completion |

Notably, the tests use the **same** `MockWorkoutService` the app uses — the
only difference is `latency: 0...0` and per-test failure config.

---

## 11. What I'd add given more time

- **Persistence migration** — versioned envelope (`{version, payload}`) with
  explicit upgrade steps. Today a corrupt or schema-changed snapshot throws
  on load and we fall back to a fresh fetch.
- **Background `BGTask`** — let the rest-completion countdown fire a local
  notification even if the user closes the app mid-rest.
- **Demo video playback** — placeholder thumbnail today. With real HLS URLs an
  `AVPlayerLayer`-backed view would slot in.
- **Settings (haptics on/off, rest auto-skip toggle)** wired through the VM.
- **Per-set elapsed tracking** — today `elapsedSeconds` rolls up at the
  exercise level. Per-set timestamps would feed richer post-workout analytics.
- **More VoiceOver polish** — custom rotor for navigating the exercise list,
  set-by-set narration as a set completes.
- **Snapshot debounce** — save on every transition today. For lower-end
  devices a 250ms debounce would reduce I/O without losing meaningful data.
- **Drop the unused `SyncStatus.failed` case** — defined for future use,
  never set. Mild over-engineering to clean up.

---

## 12. File layout

```
GuidedWorkout/                           ← repo root
├── README.md                            quick intro + setup
├── NOTES.md                             (this file)
└── GuidedWorkout/                       ← Xcode project root
    ├── GuidedWorkout.xcodeproj
    ├── GuidedWorkout/                   ← main target source
    │   ├── App/
    │   │   ├── RootContainerView.swift  owns VM, hosts NavigationStack
    │   │   └── Route.swift              enum for navigation destinations
    │   ├── Models/                      Codable value types
    │   │   ├── WorkoutSession.swift
    │   │   ├── Exercise.swift
    │   │   ├── ExerciseTarget.swift
    │   │   ├── Difficulty.swift
    │   │   ├── ExerciseProgress.swift
    │   │   ├── SyncStatus.swift
    │   │   ├── SessionSummary.swift
    │   │   ├── Milestone.swift
    │   │   ├── SessionSnapshot.swift
    │   │   └── PersistedPhase.swift
    │   ├── Services/
    │   │   ├── WorkoutServiceProtocol.swift
    │   │   └── MockWorkoutService.swift  actor, fail-once semantics
    │   ├── Persistence/
    │   │   ├── SessionStoreProtocol.swift
    │   │   └── FileSessionStore.swift   atomic JSON in Application Support
    │   ├── Timer/
    │   │   └── WorkoutTimer.swift       wall-clock based stopwatch
    │   ├── ViewModels/
    │   │   ├── ActiveSessionVM.swift    @Observable state machine + coordinator
    │   │   ├── SessionPhase.swift       runtime phase enum
    │   │   └── ActiveSessionVM+Preview.swift  DEBUG-only preview seeds
    │   ├── Theme/
    │   │   ├── AppTheme.swift           palette + softShadow modifier
    │   │   └── ExerciseStyle.swift      per-exercise SF Symbol + brand color
    │   ├── Views/
    │   │   ├── Overview/                hero + exercise carousel
    │   │   ├── Active/                  exercise + rest + ring + ribbon
    │   │   ├── Rest/                    countdown + up-next hero
    │   │   ├── Demo/                    instructions + safety
    │   │   ├── Summary/                 hero + stat tiles + per-exercise
    │   │   └── Shared/                  Chip, Haptics, PrimaryButtonStyle,
    │   │                                SetProgressDots, PendingSyncBanner,
    │   │                                TimeFormatter
    │   ├── Mocks/
    │   │   └── SeedData.swift           5 exercises from the brief
    │   └── GuidedWorkoutApp.swift       @main, DI wiring, demoFailures toggle
    └── GuidedWorkoutTests/              Swift Testing
        ├── WorkoutTimerTests.swift
        ├── SessionStoreTests.swift
        └── ActiveSessionVMTests.swift
```
