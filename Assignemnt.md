# Assignment 02: iOS Guided Workout Session

## Scenario

Build a standalone SwiftUI guided workout experience for a wellness app. A user opens today's scheduled routine, follows exercises one by one, views demo details when needed, completes or skips exercises, and sees a session summary.

This is a one-day task. Use reasonable assumptions where details are not specified, and mention them in your notes.

## Recommended Time

6 to 8 hours.

## What We Want To Evaluate

- Native SwiftUI feature delivery.
- Timer and lifecycle correctness.
- Session/progress state management.
- Local persistence and pending sync handling.
- Async service boundaries.
- Practical mobile UX for someone exercising.
- Ability to choose sane implementation details without over-engineering.

## Core Requirements

Create an iOS SwiftUI app or feature module named `GuidedWorkout`.

The flow should include:

1. Loading today's session from a mock async service.
2. A session overview.
3. An active exercise screen.
4. Rep-based and time-based exercise completion.
5. Rest timer between exercises.
6. Exercise demo/detail view.
7. Complete, skip, previous, and forward navigation.
8. Progress save after each exercise.
9. Local resume after app relaunch.
10. A pending-sync state if save fails.
11. Completion summary with milestone information.

## Service Contract

Use a protocol similar to this. You may adjust names or return types if you explain why.

```swift
protocol WorkoutServiceProtocol {
    func fetchTodaySession() async throws -> WorkoutSession
    func saveProgress(_ progress: [ExerciseProgress]) async throws
    func completeExercise(sessionId: String, exerciseId: String, progress: ExerciseProgress) async throws
    func completeSession(_ summary: SessionSummary) async throws
}
```

The mock service should support:

- One simulated initial load failure.
- One simulated progress-save failure.
- A later retry that succeeds.

## Required Seed Data

Use this session as the minimum dataset. You may add fields if your model needs them.

```json
{
  "id": "session_mobility_001",
  "schedule_id": "schedule_today_2026_06_02",
  "workout_id": "workout_lower_back_reset",
  "title": "Lower Back Reset",
  "subtitle": "A calm mobility routine for stiffness and posture",
  "estimated_minutes": 22,
  "rest_seconds_between_exercises": 30
}
```

Exercises:

| ID | Title | Area | Difficulty | Type | Sets | Target | Safety Note |
|----|-------|------|------------|------|------|--------|-------------|
| `ex_cat_cow` | Cat-Cow Mobility | Spine | beginner | time | 2 | 45 sec | Keep movement slow and comfortable. |
| `ex_glute_bridge` | Glute Bridge | Hips | beginner | reps | 3 | 12 reps | Stop if sharp back or hip pain appears. |
| `ex_dead_bug` | Dead Bug | Core | intermediate | reps | 3 | 10 reps | Avoid arching the lower back. |
| `ex_quad_stretch` | Standing Quad Stretch | Thighs | beginner | time | 2 | 30 sec | Use support for balance. |
| `ex_band_rows` | Resistance Band Rows | Upper back | intermediate | reps | 3 | 15 reps | Keep shoulders relaxed. |

Each exercise should also include:

- `thumbnail_url`
- `video_url`
- 3 to 4 instruction steps

You can use placeholder URLs such as:

```text
https://example.com/thumbnails/cat-cow.jpg
https://example.com/videos/cat-cow.m3u8
```

Do not download or stream remote media. The demo screen may show a placeholder visual and the metadata.

## Expected Progress Shape

You can model this differently if you explain why, but your implementation should preserve equivalent information.

```json
{
  "exercise_id": "ex_glute_bridge",
  "completed_sets": 3,
  "skipped": false,
  "elapsed_seconds": 142,
  "sync_status": "synced"
}
```

If a save fails, represent that locally, for example:

```json
{
  "exercise_id": "ex_dead_bug",
  "completed_sets": 2,
  "skipped": false,
  "elapsed_seconds": 80,
  "sync_status": "pending"
}
```

Expected final summary should include at least:

- Session ID
- Schedule ID
- Workout ID
- Completed exercise count
- Skipped exercise count
- Total sets completed
- Total elapsed seconds
- Optional milestone earned

## Timer Expectations

Time-based exercises should support:

- Start
- Pause
- Resume
- Reset
- Set completion when timer reaches target

Rest timer should:

- Start after an exercise is completed or skipped.
- Allow skip-rest.
- Avoid incorrect jumps when app moves to background and foreground.

Implementation detail is intentionally open. Use a simple, reliable approach and explain it.

## Output Expectations

Your submitted app should:

- Compile on Xcode 15 or later.
- Use SwiftUI and async/await.
- Keep timer/session business logic out of the view body.
- Preserve in-progress session state after relaunch.
- Preserve user progress when sync fails.
- Let the user retry pending progress sync.
- Keep controls large and clear enough for active workout use.
- Include a short `NOTES.md` with assumptions, run steps, and tradeoffs.

## Optional Bonus

- Unit tests for progress totals, pending sync, or timer state.
- SwiftUI previews for overview, active exercise, demo, and summary.
- Haptic feedback on set/exercise completion.
- VoiceOver labels for timer and progress controls.

## Rubric

| Area | Points |
|------|--------|
| Architecture and separation | 20 |
| Session/progress correctness | 20 |
| Timer and lifecycle behavior | 20 |
| Pending sync and local resume | 15 |
| Demo/detail flow | 10 |
| UX polish | 10 |
| Code quality and testability | 5 |

## Red Flags

- Timer keeps running incorrectly after navigation or app backgrounding.
- Progress summary does not match user actions.
- Sync failure loses completed work.
- Demo navigation resets the active session.
- Buttons allow impossible states, such as completing more sets than prescribed.
- No explanation of assumptions.
