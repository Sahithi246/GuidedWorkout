//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import Testing
import Foundation
@testable import GuidedWorkout

struct WorkoutTimerTests {

    @Test func snapshotIsZeroBeforeStart() async throws {
        let timer = WorkoutTimer()
        #expect(timer.snapshot() == 0)
        #expect(timer.isRunning == false)
    }

    @Test func snapshotAdvancesWithInjectedClock() async throws {
        let timer = WorkoutTimer()
        var now = Date(timeIntervalSince1970: 1000)
        timer.clock = { now }
        timer.tickInterval = 60   // suppress the UI ticker during tests

        timer.start()
        #expect(timer.snapshot() == 0)

        now = Date(timeIntervalSince1970: 1015)
        #expect(timer.snapshot() == 15)
    }

    @Test func pauseAccumulatesAndResumeContinues() async throws {
        let timer = WorkoutTimer()
        var now = Date(timeIntervalSince1970: 0)
        timer.clock = { now }
        timer.tickInterval = 60

        timer.start()
        now = now.addingTimeInterval(10)
        timer.pause()
        #expect(timer.snapshot() == 10)
        #expect(timer.isRunning == false)

        // Clock advances during pause — should NOT count.
        now = now.addingTimeInterval(30)
        #expect(timer.snapshot() == 10)

        timer.resume()
        now = now.addingTimeInterval(5)
        #expect(timer.snapshot() == 15)
    }

    @Test func resetClearsState() async throws {
        let timer = WorkoutTimer()
        var now = Date(timeIntervalSince1970: 0)
        timer.clock = { now }
        timer.tickInterval = 60

        timer.start()
        now = now.addingTimeInterval(20)
        timer.reset()
        #expect(timer.snapshot() == 0)
        #expect(timer.isRunning == false)
    }

    @Test func seedRestoresElapsedInPausedState() async throws {
        let timer = WorkoutTimer()
        var now = Date(timeIntervalSince1970: 1000)
        timer.clock = { now }
        timer.tickInterval = 60

        timer.seed(elapsed: 42)
        #expect(timer.snapshot() == 42)
        #expect(timer.isRunning == false)

        timer.resume()
        now = now.addingTimeInterval(8)
        #expect(timer.snapshot() == 50)
    }

    /// Simulates app backgrounding: clock jumps forward while the run-loop is suspended.
    /// The snapshot must reflect wall-clock truth, not a tick counter.
    @Test func snapshotIsCorrectAcrossSimulatedBackgrounding() async throws {
        let timer = WorkoutTimer()
        var now = Date(timeIntervalSince1970: 0)
        timer.clock = { now }
        timer.tickInterval = 60

        timer.start()
        now = now.addingTimeInterval(5)
        // App goes to background → real Timer wouldn't fire, but snapshot still polls.
        now = now.addingTimeInterval(120)   // gone for 2 minutes
        #expect(timer.snapshot() == 125)
    }
}
