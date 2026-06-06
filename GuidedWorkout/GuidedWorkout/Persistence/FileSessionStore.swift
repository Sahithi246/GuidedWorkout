//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import Foundation

nonisolated final class FileSessionStore: SessionStoreProtocol {

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileURL: URL) {
        self.fileURL = fileURL
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = enc
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec
    }

    static func defaultStore(fileName: String = "session_snapshot.json") throws -> FileSessionStore {
        let fm = FileManager.default
        let appSupport = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let appDir = appSupport.appendingPathComponent("GuidedWorkout", isDirectory: true)
        if !fm.fileExists(atPath: appDir.path) {
            try fm.createDirectory(at: appDir, withIntermediateDirectories: true)
        }
        return FileSessionStore(fileURL: appDir.appendingPathComponent(fileName))
    }

    func load() throws -> SessionSnapshot? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        guard !data.isEmpty else { return nil }
        return try decoder.decode(SessionSnapshot.self, from: data)
    }

    func save(_ snapshot: SessionSnapshot) throws {
        let data = try encoder.encode(snapshot)
        try data.write(to: fileURL, options: [.atomic])
    }

    func clear() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try FileManager.default.removeItem(at: fileURL)
    }
}
