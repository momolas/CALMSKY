//
//  ObserverLocation.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

import Foundation
import SwiftData

/// Represents a persistent geographical observing site or astronomical observatory.
@Model
public final class ObserverLocation {
    #Index<ObserverLocation>([\.name], [\.latitude, \.longitude])

    public var name: String = ""
    public var latitude: Double = 0.0
    public var longitude: Double = 0.0
    public var altitude: Double = 0.0
    public var bortleScale: Int = 4
    public var timeZoneIdentifier: String = "UTC"
    public var isDefaultSite: Bool = false
    public var notes: String = ""

    @Relationship(deleteRule: .cascade, inverse: \ObservationSession.location)
    public var sessions: [ObservationSession] = []

    public init(
        name: String,
        latitude: Double,
        longitude: Double,
        altitude: Double = 0.0,
        bortleScale: Int = 4,
        timeZoneIdentifier: String = TimeZone.current.identifier,
        isDefaultSite: Bool = false,
        notes: String = ""
    ) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.bortleScale = max(1, min(9, bortleScale))
        self.timeZoneIdentifier = timeZoneIdentifier
        self.isDefaultSite = isDefaultSite
        self.notes = notes
    }

    /// Converts the location to AstronomyKit GeographicCoordinates.
    public var coordinates: GeographicCoordinates {
        GeographicCoordinates(positivelyWestwardLongitude: Degree(-longitude), latitude: Degree(latitude), altitude: Meter(altitude))
    }
}
