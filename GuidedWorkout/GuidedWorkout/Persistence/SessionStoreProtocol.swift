//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import Foundation

protocol SessionStoreProtocol: Sendable {
    func load() throws -> SessionSnapshot?
    func save(_ snapshot: SessionSnapshot) throws
    func clear() throws
}
