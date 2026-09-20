//
//  SolarSystemBody.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

import Foundation

/// Canonical enumeration of major Solar System bodies providing unified value-type ephemeris access.
public enum SolarSystemBody: String, CaseIterable, Sendable, Identifiable, Codable {
    case sun
    case mercury
    case venus
    case earth
    case moon
    case mars
    case jupiter
    case saturn
    case uranus
    case neptune
    case pluto

    public var id: String { rawValue }

    /// Standard English name.
    public var name: String {
        switch self {
        case .sun: return "Sun"
        case .mercury: return "Mercury"
        case .venus: return "Venus"
        case .earth: return "Earth"
        case .moon: return "Moon"
        case .mars: return "Mars"
        case .jupiter: return "Jupiter"
        case .saturn: return "Saturn"
        case .uranus: return "Uranus"
        case .neptune: return "Neptune"
        case .pluto: return "Pluto"
        }
    }

    /// Astronomical unicode symbol.
    public var symbol: String {
        switch self {
        case .sun: return "☉"
        case .mercury: return "☿"
        case .venus: return "♀"
        case .earth: return "♁"
        case .moon: return "☽"
        case .mars: return "♂"
        case .jupiter: return "♃"
        case .saturn: return "♄"
        case .uranus: return "♅"
        case .neptune: return "♆"
        case .pluto: return "♇"
        }
    }

    /// Representative RGB display color for UI rendering.
    public var averageColor: CelestialColor {
        switch self {
        case .sun: return CelestialColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        case .mercury: return Mercury.averageColor
        case .venus: return Venus.averageColor
        case .earth: return Earth.averageColor
        case .moon: return CelestialColor(red: 0.85, green: 0.85, blue: 0.88, alpha: 1.0)
        case .mars: return Mars.averageColor
        case .jupiter: return Jupiter.averageColor
        case .saturn: return Saturn.averageColor
        case .uranus: return Uranus.averageColor
        case .neptune: return Neptune.averageColor
        case .pluto: return Pluto.averageColor
        }
    }

    /// Instantiates the corresponding legacy class object at the given Julian Day.
    public func makeObject(julianDay: JulianDay, highPrecision: Bool = true) -> any ObjectBase {
        switch self {
        case .sun: return Sun(julianDay: julianDay, highPrecision: highPrecision)
        case .mercury: return Mercury(julianDay: julianDay, highPrecision: highPrecision)
        case .venus: return Venus(julianDay: julianDay, highPrecision: highPrecision)
        case .earth: return Earth(julianDay: julianDay, highPrecision: highPrecision)
        case .moon: return Moon(julianDay: julianDay, highPrecision: highPrecision)
        case .mars: return Mars(julianDay: julianDay, highPrecision: highPrecision)
        case .jupiter: return Jupiter(julianDay: julianDay, highPrecision: highPrecision)
        case .saturn: return Saturn(julianDay: julianDay, highPrecision: highPrecision)
        case .uranus: return Uranus(julianDay: julianDay, highPrecision: highPrecision)
        case .neptune: return Neptune(julianDay: julianDay, highPrecision: highPrecision)
        case .pluto: return Pluto(julianDay: julianDay, highPrecision: highPrecision)
        }
    }

    /// Computes a lightweight, immutable, Sendable snapshot of the body's ephemeris at a given epoch.
    public func ephemeris(at julianDay: JulianDay, highPrecision: Bool = true) -> EphemerisSnapshot {
        switch self {
        case .sun:
            let sun = Sun(julianDay: julianDay, highPrecision: highPrecision)
            return EphemerisSnapshot(
                body: self,
                julianDay: julianDay,
                equatorialCoordinates: sun.equatorialCoordinates,
                eclipticCoordinates: sun.eclipticCoordinates,
                radiusVector: sun.radiusVector,
                apparentMagnitude: -26.74,
                illuminatedFraction: 1.0,
                phaseAngle: Degree(0.0)
            )
        case .moon:
            let moon = Moon(julianDay: julianDay, highPrecision: highPrecision)
            return EphemerisSnapshot(
                body: self,
                julianDay: julianDay,
                equatorialCoordinates: moon.equatorialCoordinates,
                eclipticCoordinates: moon.eclipticCoordinates,
                radiusVector: moon.radiusVector,
                apparentMagnitude: nil,
                illuminatedFraction: moon.illuminatedFraction(),
                phaseAngle: moon.phaseAngle()
            )
        case .earth:
            let earth = Earth(julianDay: julianDay, highPrecision: highPrecision)
            return EphemerisSnapshot(
                body: self,
                julianDay: julianDay,
                equatorialCoordinates: nil,
                eclipticCoordinates: earth.heliocentricEclipticCoordinates,
                radiusVector: earth.radiusVector,
                apparentMagnitude: nil,
                illuminatedFraction: 1.0,
                phaseAngle: nil
            )
        case .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune:
            guard let planet = makeObject(julianDay: julianDay, highPrecision: highPrecision) as? Planet else {
                fatalError("Expected Planet instance for \(self)")
            }
            return EphemerisSnapshot(
                body: self,
                julianDay: julianDay,
                equatorialCoordinates: planet.equatorialCoordinates,
                eclipticCoordinates: planet.heliocentricEclipticCoordinates,
                radiusVector: planet.radiusVector,
                apparentMagnitude: planet.magnitude.value,
                illuminatedFraction: planet.illuminatedFraction,
                phaseAngle: planet.phaseAngle
            )
        case .pluto:
            let pluto = Pluto(julianDay: julianDay, highPrecision: highPrecision)
            return EphemerisSnapshot(
                body: self,
                julianDay: julianDay,
                equatorialCoordinates: nil,
                eclipticCoordinates: pluto.heliocentricEclipticCoordinates,
                radiusVector: pluto.radiusVector,
                apparentMagnitude: nil,
                illuminatedFraction: nil,
                phaseAngle: nil
            )
        }
    }
}

/// An immutable, type-safe, Sendable snapshot of a celestial body's ephemeris at a specific instant.
public struct EphemerisSnapshot: Sendable, Hashable, Codable, Identifiable {
    public var id: String { "\(body.rawValue)-\(julianDay.value)" }
    public let body: SolarSystemBody
    public let julianDay: JulianDay
    public let equatorialCoordinates: EquatorialCoordinates?
    public let eclipticCoordinates: EclipticCoordinates?
    public let radiusVector: AstronomicalUnit
    public let apparentMagnitude: Double?
    public let illuminatedFraction: Double?
    public let phaseAngle: Degree?

    public init(
        body: SolarSystemBody,
        julianDay: JulianDay,
        equatorialCoordinates: EquatorialCoordinates?,
        eclipticCoordinates: EclipticCoordinates?,
        radiusVector: AstronomicalUnit,
        apparentMagnitude: Double?,
        illuminatedFraction: Double?,
        phaseAngle: Degree?
    ) {
        self.body = body
        self.julianDay = julianDay
        self.equatorialCoordinates = equatorialCoordinates
        self.eclipticCoordinates = eclipticCoordinates
        self.radiusVector = radiusVector
        self.apparentMagnitude = apparentMagnitude
        self.illuminatedFraction = illuminatedFraction
        self.phaseAngle = phaseAngle
    }
}
