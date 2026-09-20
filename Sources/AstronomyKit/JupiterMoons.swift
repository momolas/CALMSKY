//
//  JupiterMoons.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 06/11/2016.
//  MIT Licence. See LICENCE file.
//

import Foundation
import AAplus

public typealias JupiterEquatorialRadius = Double


/// These coordinates describe the position of the four great satellites of Jupiter, with respect to the planet,
/// as seen from the Earth. These apparent rectangular coordinates Z and Y are measured from the center of the disk
/// of Jupiter, in units of the planet's equatorial radius.
/// X is measured positively to the west of Jupiter, the axis coinciding with equator of the planet.
/// Y is measured positively to the north, the axis coinciding with the rotation axis of the planet.
/// Z is negative if the satellite is closer to the Earth than Jupiter, and positive otherwise.
public struct GalileanMoonRectangularCoordinates: Sendable, Codable, Hashable {
    public fileprivate(set) var X: JupiterEquatorialRadius
    public fileprivate(set) var Y: JupiterEquatorialRadius
    public fileprivate(set) var Z: Double
    
    init(coordinates: CAA3DCoordinate) {
        self.X = coordinates.X
        self.Y = coordinates.Y
        self.Z = coordinates.Z
    }
}

/// The GalileanMoon struct encompasses all properties of Galilean moons
public struct GalileanMoon: @unchecked Sendable {
    fileprivate var details: CAAGalileanMoonDetail

    /// The name of the Moon
    public var name: String

    public var MeanLongitude: Degree { get { return Degree(self.details.MeanLongitude) } }
    public var TrueLongitude: Degree { get { return Degree(self.details.TrueLongitude) } }
    public var TropicalLongitude: Degree { get { return Degree(self.details.TropicalLongitude) } }
    public var EquatorialLatitude: Degree { get { return Degree(self.details.EquatorialLatitude) } }

    public var radiusVector: AstronomicalUnit { get { return AstronomicalUnit(self.details.r) } }

    /// Returns whether the Moon is in transit or not (i.e. in front of Jupiter disk).
    public var inTransit: Bool { get { return self.details.bInTransit } }
    
    /// Returns whether the Moon is in occultation or not (i.e. behind the Jupiter disk).
    public var inOccultation: Bool { get { return self.details.bInOccultation } }

    /// Returns whether the Moon is eclipsing Jupiter.
    public var inEclipse: Bool { get { return self.details.bInEclipse } }
    
    /// Returns whether the Moon is eclipsed by Jupiter.
    public var inShadowTransit: Bool { get { return self.details.bInShadowTransit } }

    /// Returns a GalileanMoon object
    ///
    /// - Parameters:
    ///   - name: the name of the Moon
    ///   - details: the details of the moon. See Jupiter class.
    init(name: String, details: CAAGalileanMoonDetail) {
        self.name = name
        self.details = details
    }

    public func rectangularCoordinates(_ apparent: Bool = true) -> GalileanMoonRectangularCoordinates {
        let coordinates = (apparent == true) ? self.details.ApparentRectangularCoordinates : self.details.TrueRectangularCoordinates
        return GalileanMoonRectangularCoordinates(coordinates: coordinates)
    }
}

