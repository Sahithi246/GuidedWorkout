//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import Foundation
import Observation

/// Wall-clock-based stopwatch. Source of truth is Date arithmetic, not tick accumulation,
/// so it remains correct across app backgrounding, system clock pauses, and run-loop stalls.
///
/// Usage model:
///   - `start()` records `segmentStart = now` and kicks off a UI refresh ticker.
///   - `pause()` folds the current segment into `accumulated` and stops the ticker.
///   - `resume()` is an alias for `start()`.
///   - `snapshot()` is the canonical elapsed reading: `accumulated + (now - segmentStart)`.
///   - `seed(elapsed:)` restores from a persisted snapshot in a paused state.
///
/// The `Timer` is only a redraw mechanism — never the source of truth.
@Observable
final class WorkoutTimer {

    private(set) var elapsed: TimeInterval = 0
    private(set) var isRunning: Bool = false

    private var accumulated: TimeInterval = 0
    private var segmentStart: Date?
    private var ticker: Foundation.Timer?

    @ObservationIgnored
    var clock: () -> Date = { Date() }

    @ObservationIgnored
    var tickInterval: TimeInterval = 0.1

    func start() {
        guard !isRunning else { return }
        segmentStart = clock()
        isRunning = true
        startTicker()
        refresh()
    }

    func resume() { start() }

    func pause() {
        guard isRunning, let start = segmentStart else { return }
        accumulated += clock().timeIntervalSince(start)
        segmentStart = nil
        isRunning = false
        stopTicker()
        refresh()
    }

    func reset() {
        stopTicker()
        accumulated = 0
        segmentStart = nil
        isRunning = false
        elapsed = 0
    }

    /// Restore elapsed offset without starting the timer. Used to resume a persisted exercise.
    func seed(elapsed seed: TimeInterval) {
        stopTicker()
        accumulated = max(0, seed)
        segmentStart = nil
        isRunning = false
        elapsed = accumulated
    }

    /// Canonical reading. Pure function of `accumulated`, `segmentStart`, and `clock`.
    func snapshot() -> TimeInterval {
        guard let start = segmentStart else { return accumulated }
        return accumulated + clock().timeIntervalSince(start)
    }

    func refresh() {
        elapsed = snapshot()
    }

    private func startTicker() {
        stopTicker()
        let t = Foundation.Timer(timeInterval: tickInterval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        RunLoop.main.add(t, forMode: .common)
        ticker = t
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }
}
