//
//  EphemerisProvider.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

import Foundation

// MARK: - Errors

/// Errors that can occur when computing ephemeris positions.
public enum EphemerisError: Error, Sendable {
    /// The requested body is not supported by this provider.
    case bodyNotSupported(SolarSystemBody)
    /// The Julian Day is outside the valid range for this provider.
    case dateOutOfRange(JulianDay)
    /// A required data file could not be found at the expected path.
    case dataFileNotFound(String)
    /// A data file exists but is corrupted or has an unexpected format.
    case dataCorrupted(String)
    /// An internal calculation failed or an underlying engine could not be initialized.
    case calculationFailed(String)
}

extension EphemerisError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .bodyNotSupported(let body):
            return "Solar system body \(body.name) is not supported by this ephemeris provider."
        case .dateOutOfRange(let jd):
            return "Julian Day \(jd.value) is outside the valid range for this ephemeris provider."
        case .dataFileNotFound(let path):
            return "Required ephemeris data file not found at path: \(path)"
        case .dataCorrupted(let reason):
            return "Ephemeris data file is corrupted or invalid: \(reason)"
        case .calculationFailed(let reason):
            return "Ephemeris calculation failed: \(reason)"
        }
    }
}

// MARK: - Protocol

/// Abstraction for ephemeris computation engines of varying precision.
///
/// Conforming types provide heliocentric positions and state vectors for Solar System bodies.
/// Canonical numerical providers include:
/// - ``StreamingTriadProvider``: Parallel HTTP Range streaming combining NASA JPL, IMCCE, and IAA RAS models.
/// - ``TriadEphemerisProvider``: Multi-agency consensus ensemble (US DE442s, FR INPOP21a, RU EPM2021).
/// - ``SPKEphemerisProvider``: Hardware-vectorized DAF/SPK Type 2 numerical kernel reader.
/// - ``VSOP2013Provider``: High-precision planetary positions from IMCCE VSOP2013 (≈1–10 m accuracy).
/// - ``HybridEphemerisProvider``: Combines VSOP2013 (planets) with JPL DE440 (Moon, ≈1–3 cm accuracy).
///
/// All positions are returned in the **ICRS/J2000** reference frame with units of **AU** for position
/// and **AU/day** for velocity.
public protocol EphemerisProvider: Sendable {
    /// Heliocentric position of a Solar System body in AU (ICRS/J2000).
    ///
    /// - Parameters:
    ///   - body: The target Solar System body.
    ///   - jd: The epoch expressed as a Julian Day (TDB).
    /// - Returns: Heliocentric position vector in astronomical units.
    /// - Throws: ``EphemerisError`` if the body is unsupported or the date is out of range.
    func position(for body: SolarSystemBody, at jd: JulianDay) throws -> Vector3D

    /// Full 6D state vector (position + velocity) of a Solar System body (ICRS/J2000).
    ///
    /// - Parameters:
    ///   - body: The target Solar System body.
    ///   - jd: The epoch expressed as a Julian Day (TDB).
    /// - Returns: State vector with position in AU and velocity in AU/day.
    /// - Throws: ``EphemerisError`` if the body is unsupported or the date is out of range.
    func stateVector(for body: SolarSystemBody, at jd: JulianDay) throws -> StateVector

    /// Heliocentric positions of a Solar System body over an array of epochs (ICRS/J2000).
    ///
    /// - Parameters:
    ///   - body: The target Solar System body.
    ///   - dates: The array of epochs expressed as Julian Days (TDB).
    /// - Returns: Array of heliocentric position vectors in astronomical units.
    /// - Throws: ``EphemerisError`` if the body is unsupported or any date is out of range.
    func positions(for body: SolarSystemBody, at dates: [JulianDay]) throws -> [Vector3D]

    /// Full 6D state vectors of a Solar System body over an array of epochs (ICRS/J2000).
    ///
    /// - Parameters:
    ///   - body: The target Solar System body.
    ///   - dates: The array of epochs expressed as Julian Days (TDB).
    /// - Returns: Array of state vectors in AU and AU/day.
    /// - Throws: ``EphemerisError`` if the body is unsupported or any date is out of range.
    func stateVectors(for body: SolarSystemBody, at dates: [JulianDay]) throws -> [StateVector]
}

// MARK: - Batch Default Implementations

extension EphemerisProvider {
    public func positions(for body: SolarSystemBody, at dates: [JulianDay]) throws -> [Vector3D] {
        var results: [Vector3D] = []
        results.reserveCapacity(dates.count)
        for date in dates {
            try Task.checkCancellation()
            results.append(try position(for: body, at: date))
        }
        return results
    }

    public func stateVectors(for body: SolarSystemBody, at dates: [JulianDay]) throws -> [StateVector] {
        var results: [StateVector] = []
        results.reserveCapacity(dates.count)
        for date in dates {
            try Task.checkCancellation()
            results.append(try stateVector(for: body, at: date))
        }
        return results
    }
}
