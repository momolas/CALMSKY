//
//  AstronomySchema.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

import Foundation
import SwiftData

/// Helper factory for managing SwiftData storage for AstronomyKit models.
public enum AstronomyDataStore: Sendable {
    /// Schema definition containing all AstronomyKit persistent models.
    public static let schema = Schema([
        ObserverLocation.self,
        ObservationSession.self,
        ObservationLog.self
    ])

    /// Creates an in-memory ModelContainer ideal for unit testing and ephemeral sessions.
    public static func makeInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// Creates a persistent on-disk ModelContainer with the given configuration name.
    public static func makeDefaultContainer(name: String = "AstronomyKitStore") throws -> ModelContainer {
        let configuration = ModelConfiguration(name, schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
