//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import Testing
import Foundation
@testable import GuidedWorkout

struct SessionStoreTests {

    private func makeTempStore() throws -> (FileSessionStore, URL) {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("guidedworkout-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("snapshot.json")
        return (FileSessionStore(fileURL: url), url)
    }

    private func sampleSnapshot() -> SessionSnapshot {
        let session = SeedData.todaySession
        let progress = session.exercises.map { ExerciseProgress.initial(for: $0.id) }
        return SessionSnapshot(
            session: session,
            progress: progress,
            phase: .exercising(index: 2),
            elapsedOnCurrent: 14,
            restRemainingSeconds: nil,
            startedAt: Date(timeIntervalSince1970: 1000),
            lastUpdatedAt: Date(timeIntervalSince1970: 1100)
        )
    }

    @Test func loadReturnsNilWhenFileMissing() throws {
        let (store, _) = try makeTempStore()
        #expect(try store.load() == nil)
    }

    @Test func saveThenLoadRoundTrips() throws {
        let (store, _) = try makeTempStore()
        let snap = sampleSnapshot()
        try store.save(snap)
        let loaded = try #require(try store.load())
        #expect(loaded == snap)
    }

    @Test func clearRemovesFile() throws {
        let (store, url) = try makeTempStore()
        try store.save(sampleSnapshot())
        #expect(FileManager.default.fileExists(atPath: url.path))
        try store.clear()
        #expect(FileManager.default.fileExists(atPath: url.path) == false)
        #expect(try store.load() == nil)
    }

    @Test func clearOnMissingFileIsSafe() throws {
        let (store, _) = try makeTempStore()
        try store.clear()
        try store.clear()   // second clear is a no-op
    }

    @Test func snapshotPreservesRestPhase() throws {
        let (store, _) = try makeTempStore()
        var snap = sampleSnapshot()
        snap.phase = .resting(nextIndex: 3)
        snap.restRemainingSeconds = 12
        try store.save(snap)
        let loaded = try #require(try store.load())
        if case .resting(let i) = loaded.phase {
            #expect(i == 3)
        } else {
            Issue.record("expected .resting phase")
        }
        #expect(loaded.restRemainingSeconds == 12)
    }
}
