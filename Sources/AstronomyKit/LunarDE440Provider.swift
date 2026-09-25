//
//  LunarDE440Provider.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

import Foundation

/// Provides centimeter-precision geocentric lunar positions from JPL DE440 / DE442 ephemeris data.
///
/// This provider reads a subset of the JPL DE440/DE442 SPK/BSP file containing only the
/// Moon's geocentric position relative to the Earth-Moon Barycenter (NAIF target 301,
/// center 3) or the Earth (NAIF target 301, center 399).
///
/// The position data is stored as Chebyshev polynomial coefficients (SPK Type 2) and
/// is evaluated using the ``SPKReader`` pure-Swift parser.
///
/// ## Precision
/// - Position accuracy: ≈1–3 cm over 1550–2650 CE (DE440), 1849–2150 CE (DE442s), or 1900–2050 CE (DE440s).
/// - Velocity accuracy: ≈0.01 mm/s.
///
/// ## Data Files
/// Use ``EphemerisDataManager`` to download the required SPK file:
/// - `de442s.bsp` (≈31 MB, 1849–2150 CE, recommended official baseline)
/// - `de440.bsp` (≈115 MB, 1550–2650 CE)
/// /// Typealias allowing callers to use ``LunarDE442sProvider`` or generic ``LunarSPKProvider`` interchangeably.
public typealias LunarDE442sProvider = LunarDE440Provider
public typealias LunarDE442Provider = LunarDE440Provider
public typealias LunarSPKProvider = LunarDE440Provider

public final class LunarDE440Provider: Sendable {

    // MARK: - Constants

    /// NAIF body ID for the Moon.
    private static let moonID: Int32 = 301

    /// NAIF body ID for the Earth-Moon Barycenter.
    private static let embID: Int32 = 3

    /// NAIF body ID for the Earth.
    private static let earthID: Int32 = 399

    /// Kilometers per Astronomical Unit (IAU 2012 exact value).
    private static let kmPerAU: Double = 149_597_870.700

    /// Seconds per day.
    private static let secondsPerDay: Double = 86400.0

    // MARK: - Properties

    /// The underlying SPK file reader.
    private let spkReader: SPKReader

    /// The Moon segment found in the SPK file (Moon relative to EMB or Earth).
    private let moonSegment: SPKReader.SegmentDescriptor

    /// Whether the Moon segment is relative to Earth (399) rather than EMB (3).
    private let isMoonRelativeToEarth: Bool

    // MARK: - Initialization

    /// Creates a lunar ephemeris provider from a DE440 SPK file.
    ///
    /// - Parameter spkFileURL: Path to the DE440 `.bsp` file.
    /// - Throws: ``EphemerisError`` if the file cannot be read or has no lunar segment.
    public init(spkFileURL: URL) throws {
        self.spkReader = try SPKReader(url: spkFileURL)

        // Look for Moon segment: first try Moon relative to Earth (301→399),
        // then try Moon relative to EMB (301→3)
        if let seg = spkReader.segments.first(where: {
            $0.targetID == Self.moonID && $0.centerID == Self.earthID && $0.dataType == 2
        }) {
            self.moonSegment = seg
            self.isMoonRelativeToEarth = true
        } else if let seg = spkReader.segments.first(where: {
            $0.targetID == Self.moonID && $0.centerID == Self.embID && $0.dataType == 2
        }) {
            self.moonSegment = seg
            self.isMoonRelativeToEarth = false
        } else {
            throw EphemerisError.dataCorrupted(
                "No lunar segment (target=301) found in \(spkFileURL.lastPathComponent)"
            )
        }
    }

    /// Scale factor converting Moon/EMB vector to Moon/Earth (geocentric) vector.
    /// If segment center is already Earth (399), factor is 1.0.
    /// If segment center is EMB (3), r_Moon/Earth = r_Moon/EMB * (1 + 1 / 81.30056907).
    public var lunarScaleFactor: Double {
        isMoonRelativeToEarth ? 1.0 : (1.0 + 1.0 / 81.30056907)
    }

    // MARK: - Public API

    /// Geocentric position of the Moon in AU (ICRS/J2000, TDB).
    ///
    /// - Parameter jd: Julian Day in TDB time scale.
    /// - Returns: Position vector relative to the Earth center, in astronomical units.
    /// - Throws: ``EphemerisError/dateOutOfRange(_:)`` if the epoch is outside the kernel coverage.
    public func geocentricPosition(at jd: JulianDay) throws -> Vector3D {
        let result = try evaluate(at: jd)
        // Convert from km to AU, scaling to Earth center if stored relative to EMB
        return (result.position * lunarScaleFactor) / Self.kmPerAU
    }

    /// Geocentric state vector of the Moon (position in AU, velocity in AU/day).
    ///
    /// - Parameter jd: Julian Day in TDB time scale.
    /// - Returns: State vector relative to the Earth center, in AU and AU/day.
    /// - Throws: ``EphemerisError/dateOutOfRange(_:)`` if the epoch is outside the kernel coverage.
    public func geocentricStateVector(at jd: JulianDay) throws -> StateVector {
        let result = try evaluate(at: jd)
        let scaledPos = result.position * lunarScaleFactor
        let scaledVel = result.velocity * lunarScaleFactor
        return StateVector(
            position: scaledPos / Self.kmPerAU,
            velocity: scaledVel * (Self.secondsPerDay / Self.kmPerAU)
        )
    }

    /// Geocentric positions of the Moon in AU over an array of epochs (ICRS/J2000, TDB).
    public func geocentricPositions(at dates: [JulianDay]) throws -> [Vector3D] {
        let epochs = dates.map { SPKReader.julianDayToTDBSeconds($0.value) }
        for (i, epoch) in epochs.enumerated() {
            guard epoch >= moonSegment.startEpoch, epoch <= moonSegment.endEpoch else {
                throw EphemerisError.dateOutOfRange(dates[i])
            }
        }
        let batch = try spkReader.evaluateBatch(segment: moonSegment, epochsTDB: epochs)
        let factor = lunarScaleFactor
        return batch.map { ($0.position * factor) / Self.kmPerAU }
    }

    /// Geocentric state vectors of the Moon over an array of epochs (ICRS/J2000, TDB).
    public func geocentricStateVectors(at dates: [JulianDay]) throws -> [StateVector] {
        let epochs = dates.map { SPKReader.julianDayToTDBSeconds($0.value) }
        for (i, epoch) in epochs.enumerated() {
            guard epoch >= moonSegment.startEpoch, epoch <= moonSegment.endEpoch else {
                throw EphemerisError.dateOutOfRange(dates[i])
            }
        }
        let batch = try spkReader.evaluateBatch(segment: moonSegment, epochsTDB: epochs)
        let factor = lunarScaleFactor
        return batch.map {
            StateVector(
                position: ($0.position * factor) / Self.kmPerAU,
                velocity: ($0.velocity * factor) * (Self.secondsPerDay / Self.kmPerAU)
            )
        }
    }

    // MARK: - Private

    /// Evaluates the Moon segment at the given epoch.
    private func evaluate(at jd: JulianDay) throws -> SPKReader.EvaluationResult {
        let epochTDB = SPKReader.julianDayToTDBSeconds(jd.value)

        guard epochTDB >= moonSegment.startEpoch, epochTDB <= moonSegment.endEpoch else {
            throw EphemerisError.dateOutOfRange(jd)
        }

        return try spkReader.evaluate(segment: moonSegment, epochTDB: epochTDB)
    }
}
