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

/// Dedicated ModelActor for thread-safe background observation persistence.
@ModelActor
public actor AstronomyObservationActor {
    /// Inserts a new observation session and saves changes, returning the persistent identifier.
    public func insertSession(
        date: Date = .now,
        observerName: String = "",
        seeingScale: Int = 3,
        transparency: Int = 3,
        locationID: PersistentIdentifier? = nil
    ) throws -> PersistentIdentifier {
        let location = locationID.flatMap { modelContext.model(for: $0) as? ObserverLocation }
        let session = ObservationSession(
            date: date,
            observerName: observerName,
            seeingScale: seeingScale,
            transparency: transparency,
            location: location
        )
        modelContext.insert(session)
        try modelContext.save()
        return session.persistentModelID
    }

    /// Inserts a new observation log entry and saves changes.
    public func insertLog(
        targetName: String,
        timestamp: Date = .now,
        sessionID: PersistentIdentifier? = nil
    ) throws -> PersistentIdentifier {
        let session = sessionID.flatMap { modelContext.model(for: $0) as? ObservationSession }
        let log = ObservationLog(timestamp: timestamp, targetName: targetName, session: session)
        modelContext.insert(log)
        try modelContext.save()
        return log.persistentModelID
    }

    /// Inserts a new observer location preset and saves changes.
    public func insertLocation(
        name: String,
        latitude: Double,
        longitude: Double,
        altitude: Double = 0.0,
        bortleScale: Int = 4,
        timeZoneIdentifier: String = TimeZone.current.identifier,
        isDefaultSite: Bool = false,
        notes: String = ""
    ) throws -> PersistentIdentifier {
        let location = ObserverLocation(
            name: name,
            latitude: latitude,
            longitude: longitude,
            altitude: altitude,
            bortleScale: bortleScale,
            timeZoneIdentifier: timeZoneIdentifier,
            isDefaultSite: isDefaultSite,
            notes: notes
        )
        modelContext.insert(location)
        try modelContext.save()
        return location.persistentModelID
    }
}
