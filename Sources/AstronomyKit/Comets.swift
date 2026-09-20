//
//  Comets.swift
//  SwiftAA
//
//  Created for SwiftAA.
//  MIT Licence. See LICENCE file.
//

import Foundation
import AAplus

/// Orbital elements of a body in a parabolic orbit (e.g. non-periodic comets).
public struct ParabolicOrbitElements: Sendable, Codable, Hashable {
    /// Perihelion distance in Astronomical Units (q)
    public let perihelionDistance: AstronomicalUnit
    /// Inclination in degrees (i)
    public let inclination: Degree
    /// Argument of perihelion in degrees (w)
    public let argumentOfPerihelion: Degree
    /// Longitude of ascending node in degrees (omega)
    public let longitudeOfAscendingNode: Degree
    /// Julian Day of epoch of the equinox
    public let jdEquinox: JulianDay
    /// Julian Day of time of perihelion passage (T)
    public let timeOfPerihelion: JulianDay

    public init(perihelionDistance: AstronomicalUnit, inclination: Degree, argumentOfPerihelion: Degree, longitudeOfAscendingNode: Degree, jdEquinox: JulianDay, timeOfPerihelion: JulianDay) {
        self.perihelionDistance = perihelionDistance
        self.inclination = inclination
        self.argumentOfPerihelion = argumentOfPerihelion
        self.longitudeOfAscendingNode = longitudeOfAscendingNode
        self.jdEquinox = jdEquinox
        self.timeOfPerihelion = timeOfPerihelion
    }
}

/// 3D rectangular Cartesian coordinates.
public struct Coordinates3D: Sendable, Codable, Hashable {
    public let x: Double
    public let y: Double
    public let z: Double
    
    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}

/// Ephemeris details for a body in a parabolic orbit.
public struct ParabolicOrbitDetails: Sendable, Codable, Hashable {
    /// Heliocentric rectangular equatorial coordinates (X, Y, Z in AU)
    public let heliocentricRectangularEquatorial: Coordinates3D
    /// Heliocentric rectangular ecliptical coordinates (X, Y, Z in AU)
    public let heliocentricRectangularEcliptical: Coordinates3D
    /// Heliocentric ecliptic longitude in degrees
    public let heliocentricEclipticLongitude: Degree
    /// Heliocentric ecliptic latitude in degrees
    public let heliocentricEclipticLatitude: Degree
    /// Astrometric Right Ascension
    public let astrometricRightAscension: Hour
    /// Astrometric Declination
    public let astrometricDeclination: Degree
    /// Astrometric Geocentric distance in AU
    public let astrometricGeocentricDistance: AstronomicalUnit
    /// Elongation from Sun in degrees
    public let elongation: Degree
    /// Phase angle in degrees
    public let phaseAngle: Degree

    public init(heliocentricRectangularEquatorial: Coordinates3D, heliocentricRectangularEcliptical: Coordinates3D, heliocentricEclipticLongitude: Degree, heliocentricEclipticLatitude: Degree, astrometricRightAscension: Hour, astrometricDeclination: Degree, astrometricGeocentricDistance: AstronomicalUnit, elongation: Degree, phaseAngle: Degree) {
        self.heliocentricRectangularEquatorial = heliocentricRectangularEquatorial
        self.heliocentricRectangularEcliptical = heliocentricRectangularEcliptical
        self.heliocentricEclipticLongitude = heliocentricEclipticLongitude
        self.heliocentricEclipticLatitude = heliocentricEclipticLatitude
        self.astrometricRightAscension = astrometricRightAscension
        self.astrometricDeclination = astrometricDeclination
        self.astrometricGeocentricDistance = astrometricGeocentricDistance
        self.elongation = elongation
        self.phaseAngle = phaseAngle
    }
}

/// Helper methods for parabolic orbits.
public struct ParabolicOrbit: Sendable {
    
    /// Calculate details of a parabolic object at a given Julian Day.
    /// - Parameters:
    ///   - jd: Julian Day of observation.
    ///   - elements: Parabolic orbital elements.
    ///   - highPrecision: If true, uses high-precision VSOP87 calculations.
    /// - Returns: ParabolicOrbitDetails.
    public static func calculate(julianDay: JulianDay, elements: ParabolicOrbitElements, highPrecision: Bool = true) -> ParabolicOrbitDetails {
        var cElements = CAAParabolicObjectElements()
        cElements.q = elements.perihelionDistance.value
        cElements.i = elements.inclination.value
        cElements.w = elements.argumentOfPerihelion.value
        cElements.omega = elements.longitudeOfAscendingNode.value
        cElements.JDEquinox = elements.jdEquinox.value
        cElements.T = elements.timeOfPerihelion.value
        
        let details = CAAParabolic.Calculate(julianDay.value, cElements, highPrecision, 0.000001)
        
        return ParabolicOrbitDetails(
            heliocentricRectangularEquatorial: Coordinates3D(x: details.HeliocentricRectangularEquatorial.X, y: details.HeliocentricRectangularEquatorial.Y, z: details.HeliocentricRectangularEquatorial.Z),
            heliocentricRectangularEcliptical: Coordinates3D(x: details.HeliocentricRectangularEcliptical.X, y: details.HeliocentricRectangularEcliptical.Y, z: details.HeliocentricRectangularEcliptical.Z),
            heliocentricEclipticLongitude: Degree(details.HeliocentricEclipticLongitude),
            heliocentricEclipticLatitude: Degree(details.HeliocentricEclipticLatitude),
            astrometricRightAscension: Hour(details.AstrometricGeocentricRA),
            astrometricDeclination: Degree(details.AstrometricGeocentricDeclination),
            astrometricGeocentricDistance: AstronomicalUnit(details.AstrometricGeocentricDistance),
            elongation: Degree(details.Elongation),
            phaseAngle: Degree(details.PhaseAngle)
        )
    }
}
