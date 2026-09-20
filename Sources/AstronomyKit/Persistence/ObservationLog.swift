//
//  ObservationLog.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

import Foundation
import SwiftData

/// Represents an individual observation record for a target celestial body.
@Model
public final class ObservationLog {
    #Index<ObservationLog>([\.timestamp], [\.targetName])

    public var timestamp: Date = Date.now
    public var targetName: String = ""
    public var bodyRawValue: String?
    public var rightAscensionHours: Double?
    public var declinationDegrees: Double?
    public var apparentMagnitude: Double?
    public var eyepieceFocalLength: Double?
    public var magnification: Double?
    public var filterUsed: String?
    public var notes: String = ""
    public var rating: Int = 3

    public var session: ObservationSession?

    public init(
        timestamp: Date = .now,
        targetName: String,
        body: SolarSystemBody? = nil,
        rightAscensionHours: Double? = nil,
        declinationDegrees: Double? = nil,
        apparentMagnitude: Double? = nil,
        eyepieceFocalLength: Double? = nil,
        magnification: Double? = nil,
        filterUsed: String? = nil,
        notes: String = "",
        rating: Int = 3,
        session: ObservationSession? = nil
    ) {
        self.timestamp = timestamp
        self.targetName = targetName
        self.bodyRawValue = body?.rawValue
        self.rightAscensionHours = rightAscensionHours
        self.declinationDegrees = declinationDegrees
        self.apparentMagnitude = apparentMagnitude
        self.eyepieceFocalLength = eyepieceFocalLength
        self.magnification = magnification
        self.filterUsed = filterUsed
        self.notes = notes
        self.rating = max(1, min(5, rating))
        self.session = session
    }

    /// Target Solar System body if applicable.
    public var solarSystemBody: SolarSystemBody? {
        get {
            guard let raw = bodyRawValue else { return nil }
            return SolarSystemBody(rawValue: raw)
        }
        set {
            bodyRawValue = newValue?.rawValue
            if let b = newValue {
                targetName = b.name
            }
        }
    }

    /// Corresponding Julian Day for the observation instant.
    public var julianDay: JulianDay {
        JulianDay(timestamp)
    }
}
