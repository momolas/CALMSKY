//
//  Pluto.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 19/06/16.
//  MIT Licence. See LICENCE file.
//

import Foundation
import AAplus

/// The Pluto dwarf planet.
public final class Pluto: DwarfPlanet, @unchecked Sendable {

    /// The average color of the planet.
    public class var averageColor: CelestialColor {
        get { return CelestialColor(red: 0.776, green:0.620, blue:0.486, alpha: 1.0) }
    }

    /// The heliocentric ecliptic coordinates of Pluto.
    public var heliocentricEclipticCoordinates: EclipticCoordinates {
        let lon = Degree(CAAPluto.EclipticLongitude(self.julianDay.value))
        let lat = Degree(CAAPluto.EclipticLatitude(self.julianDay.value))
        return EclipticCoordinates(lambda: lon, beta: lat)
    }

    /// The distance from the Sun in Astronomical Units.
    public var radiusVector: AstronomicalUnit {
        return AstronomicalUnit(CAAPluto.RadiusVector(self.julianDay.value))
    }
}

