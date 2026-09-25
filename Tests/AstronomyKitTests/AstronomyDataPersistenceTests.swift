//
//  AstronomyDataPersistenceTests.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

import Testing
import Foundation
import SwiftData
@testable import AstronomyKit

@Suite("SwiftData Astronomical Persistence Tests")
struct AstronomyDataPersistenceTests {

    @Test("ObserverLocation creation and coordinates conversion")
    func testObserverLocation() throws {
        let container = try AstronomyDataStore.makeInMemoryContainer()
        let context = ModelContext(container)

        let picDuMidi = ObserverLocation(
            name: "Pic du Midi de Bigorre",
            latitude: 42.9369,
            longitude: 0.1411,
            altitude: 2877.0,
            bortleScale: 2,
            timeZoneIdentifier: "Europe/Paris",
            isDefaultSite: true,
            notes: "High altitude observatory in the French Pyrenees."
        )
        context.insert(picDuMidi)
        try context.save()

        let descriptor = FetchDescriptor<ObserverLocation>(predicate: #Predicate { $0.isDefaultSite })
        let results = try context.fetch(descriptor)

        #expect(results.count == 1)
        let site = try #require(results.first)
        #expect(site.name == "Pic du Midi de Bigorre")
        #expect(site.bortleScale == 2)
        #expect(site.altitude == 2877.0)

        // Coordinates check
        let coords = site.coordinates
        #expect(abs(coords.latitude.value - 42.9369) < 1e-4)
        #expect(abs(coords.longitude.value - (-0.1411)) < 1e-4)
    }

    @Test("Deleting ObserverLocation nullifies session.location without deleting session or logs")
    func testLocationDeletionNullifiesSession() throws {
        let container = try AstronomyDataStore.makeInMemoryContainer()
        let context = ModelContext(container)

        let observatory = ObserverLocation(name: "Calar Alto", latitude: 37.2236, longitude: -2.5463)
        context.insert(observatory)

        let session = ObservationSession(date: .now, observerName: "Herschel", location: observatory)
        context.insert(session)

        let log = ObservationLog(targetName: "Uranus", session: session)
        context.insert(log)
        try context.save()

        // Deleting the location preset must nullify session.location and preserve both session and log
        context.delete(observatory)
        try context.save()

        let remainingSessions = try context.fetch(FetchDescriptor<ObservationSession>())
        #expect(remainingSessions.count == 1)
        #expect(remainingSessions.first?.location == nil)

        let remainingLogs = try context.fetch(FetchDescriptor<ObservationLog>())
        #expect(remainingLogs.count == 1)
        #expect(remainingLogs.first?.targetName == "Uranus")
    }

    @Test("ObservationSession with cascading ObservationLogs")
    func testSessionAndLogCascadingRelationship() throws {
        let container = try AstronomyDataStore.makeInMemoryContainer()
        let context = ModelContext(container)

        let location = ObserverLocation(name: "Teide Observatory", latitude: 28.3005, longitude: -16.5101, altitude: 2390)
        context.insert(location)

        let session = ObservationSession(
            date: .now,
            observerName: "Galileo",
            seeingScale: 2,
            transparency: 4,
            telescopeDescription: "Schmidt-Cassegrain 280mm f/10",
            location: location
        )
        context.insert(session)

        let jupiterLog = ObservationLog(
            targetName: "Jupiter",
            body: .jupiter,
            magnification: 180,
            notes: "Great Red Spot well defined near central meridian.",
            rating: 5,
            session: session
        )
        let saturnLog = ObservationLog(
            targetName: "Saturn",
            body: .saturn,
            magnification: 220,
            notes: "Cassini division clearly visible across rings.",
            rating: 5,
            session: session
        )
        context.insert(jupiterLog)
        context.insert(saturnLog)
        try context.save()

        // Fetch logs
        let logDescriptor = FetchDescriptor<ObservationLog>()
        let allLogs = try context.fetch(logDescriptor)
        #expect(allLogs.count == 2)

        // Test cascade deletion: deleting session must cascade to its logs
        context.delete(session)
        try context.save()

        let remainingLogs = try context.fetch(logDescriptor)
        #expect(remainingLogs.isEmpty)

        // Location should remain intact
        let locationDescriptor = FetchDescriptor<ObserverLocation>()
        let remainingLocations = try context.fetch(locationDescriptor)
        #expect(remainingLocations.count == 1)
    }

    @Test("Predicate query filtering on rating and targets")
    func testLogPredicates() throws {
        let container = try AstronomyDataStore.makeInMemoryContainer()
        let context = ModelContext(container)

        let log1 = ObservationLog(targetName: "Mars", rating: 4)
        let log2 = ObservationLog(targetName: "Moon", rating: 5)
        let log3 = ObservationLog(targetName: "Venus", rating: 2)

        context.insert(log1)
        context.insert(log2)
        context.insert(log3)
        try context.save()

        let highRatingDescriptor = FetchDescriptor<ObservationLog>(predicate: #Predicate { $0.rating >= 4 })
        let highRatingLogs = try context.fetch(highRatingDescriptor)
        #expect(highRatingLogs.count == 2)

        let marsDescriptor = FetchDescriptor<ObservationLog>(predicate: #Predicate { $0.targetName == "Mars" })
        let marsLogs = try context.fetch(marsDescriptor)
        #expect(marsLogs.count == 1)
        #expect(marsLogs.first?.targetName == "Mars")
    }

    @Test("AstronomyObservationActor safely inserts models in background actor context")
    func testAstronomyObservationActorBackgroundOperations() async throws {
        let container = try AstronomyDataStore.makeInMemoryContainer()
        let actor = AstronomyObservationActor(modelContainer: container)

        let locID = try await actor.insertLocation(
            name: "Mauna Kea",
            latitude: 19.8206,
            longitude: -155.4681,
            altitude: 4205
        )
        let sessionID = try await actor.insertSession(
            observerName: "Keck Observer",
            seeingScale: 1,
            locationID: locID
        )
        let logID = try await actor.insertLog(targetName: "Neptune", sessionID: sessionID)

        #expect(locID != sessionID)
        #expect(sessionID != logID)
    }
}
