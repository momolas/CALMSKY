//
//  AnalyticalEphemerisProvider.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

import Foundation

/// Lightweight ephemeris provider using the built-in VSOP87 + ELP2000 analytical theories.
///
/// This is the **default provider** that requires no external data files.
/// It wraps the existing AstronomyKit/AA+ engine behind the ``EphemerisProvider`` protocol,
/// enabling seamless swapping with higher-precision providers.
///
/// ## Precision
/// - Planets (VSOP87): ≈100–500 meters (modern epoch), degrading for dates far from J2000.
/// - Moon (ELP2000/ELPMPP02): ≈10–50 meters.
///
/// ## Usage
/// ```swift
/// let provider = AnalyticalEphemerisProvider()
/// let marsPos = try provider.position(for: .mars, at: jd)
/// ```
public struct AnalyticalEphemerisProvider: EphemerisProvider, Sendable {

    /// Creates an analytical ephemeris provider.
    ///
    /// No initialization parameters are needed — all data is compiled directly into the library.
    public init() {}

    /// Heliocentric position of a Solar System body in AU (ICRS/J2000).
    ///
    /// Positions are computed from the ecliptic coordinates provided by VSOP87 (planets)
    /// and ELP2000 (Moon), then converted to equatorial (ICRS) coordinates.
    public func position(for body: SolarSystemBody, at jd: JulianDay) throws -> Vector3D {
        switch body {
        case .sun:
            return .zero

        case .moon:
            let moon = Moon(julianDay: jd, highPrecision: true)
            // Moon's ecliptic coordinates give geocentric position; convert to heliocentric
            // by adding Earth's heliocentric position
            let earthPos = try position(for: .earth, at: jd)
            let moonRA = moon.equatorialCoordinates.rightAscension.inDegrees.value
            let moonDec = moon.equatorialCoordinates.declination.value
            let moonDist = moon.radiusVector.value // in AU
            let moonGeo = Vector3D.fromSpherical(ra: moonRA, dec: moonDec, distance: moonDist)
            return earthPos + moonGeo

        case .earth:
            let earth = Earth(julianDay: jd, highPrecision: true)
            let ecliptic = earth.heliocentricEclipticCoordinates
            let obliquity = Earth(julianDay: jd).obliquityOfEcliptic(mean: true).inRadians.value
            return Self.eclipticToEquatorial(
                longitude: ecliptic.celestialLongitude.inRadians.value,
                latitude: ecliptic.celestialLatitude.inRadians.value,
                radius: earth.radiusVector.value,
                obliquity: obliquity
            )

        case .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune:
            guard let planet = body.makeObject(julianDay: jd, highPrecision: true) as? Planet else {
                throw EphemerisError.bodyNotSupported(body)
            }
            let ecliptic = planet.heliocentricEclipticCoordinates
            let obliquity = Earth(julianDay: jd).obliquityOfEcliptic(mean: true).inRadians.value
            return Self.eclipticToEquatorial(
                longitude: ecliptic.celestialLongitude.inRadians.value,
                latitude: ecliptic.celestialLatitude.inRadians.value,
                radius: planet.radiusVector.value,
                obliquity: obliquity
            )

        case .pluto:
            let pluto = Pluto(julianDay: jd, highPrecision: true)
            let ecliptic = pluto.heliocentricEclipticCoordinates
            let obliquity = Earth(julianDay: jd).obliquityOfEcliptic(mean: true).inRadians.value
            return Self.eclipticToEquatorial(
                longitude: ecliptic.celestialLongitude.inRadians.value,
                latitude: ecliptic.celestialLatitude.inRadians.value,
                radius: pluto.radiusVector.value,
                obliquity: obliquity
            )
        }
    }

    // MARK: - Coordinate Transformation

    /// Converts spherical heliocentric ecliptic coordinates to equatorial Cartesian coordinates (ICRS/J2000).
    private static func eclipticToEquatorial(
        longitude: Double,
        latitude: Double,
        radius: Double,
        obliquity: Double
    ) -> Vector3D {
        let cosLat = cos(latitude)
        let xEcl = radius * cosLat * cos(longitude)
        let yEcl = radius * cosLat * sin(longitude)
        let zEcl = radius * sin(latitude)
        let cosObl = cos(obliquity)
        let sinObl = sin(obliquity)
        let xEq = xEcl
        let yEq = yEcl * cosObl - zEcl * sinObl
        let zEq = yEcl * sinObl + zEcl * cosObl
        return Vector3D(x: xEq, y: yEq, z: zEq)
    }

    /// State vector approximation using numerical differentiation.
    ///
    /// Since the analytical engine does not directly provide velocities, the velocity
    /// is computed via a central difference with a 0.01-day step size (≈14 minutes).
    public func stateVector(for body: SolarSystemBody, at jd: JulianDay) throws -> StateVector {
        let pos = try position(for: body, at: jd)

        // Central difference for velocity: v ≈ (pos(t+h) - pos(t-h)) / (2h)
        let h = 0.01 // days (≈14.4 minutes)
        let posFwd = try position(for: body, at: JulianDay(jd.value + h))
        let posBwd = try position(for: body, at: JulianDay(jd.value - h))
        let velocity = (posFwd - posBwd) / (2.0 * h)

        return StateVector(position: pos, velocity: velocity)
    }
}
