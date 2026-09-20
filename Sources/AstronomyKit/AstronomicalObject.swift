//
//  AstronomicalObject.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 17/12/2016.
//  MIT Licence. See LICENCE file.
//

import Foundation

public final class AstronomicalObject: ObjectBase, CelestialBody, @unchecked Sendable {
    public let name: String
    public let julianDay: JulianDay
    public let highPrecision: Bool
    public let equatorialCoordinates: EquatorialCoordinates

    public init(name: String, coordinates: EquatorialCoordinates, julianDay: JulianDay, highPrecision: Bool = true) {
        self.name = name
        self.julianDay = julianDay
        self.equatorialCoordinates = coordinates
        self.highPrecision = highPrecision
    }
    
    public required init(julianDay: JulianDay, highPrecision: Bool) {
        fatalError("init(julianDay:highPrecision:) cannot be implemented.")
    }

    /// The radius vector (i.e. the distance to the Sun). Returns -1. Only for conformance to CelestialBody.
    public var radiusVector: AstronomicalUnit { get { return -1 } }

    public static let apparentRiseSetAltitude = ArcMinute(-34).inDegrees // See AA p.101
}
