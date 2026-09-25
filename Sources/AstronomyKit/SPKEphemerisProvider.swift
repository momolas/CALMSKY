//
//  SPKEphemerisProvider.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

import Foundation

/// High-precision ephemeris provider reading arbitrary SPK Type 2 kernel files (JPL DE442s, IMCCE INPOP21a, IAA RAS EPM2021).
///
/// `SPKEphemerisProvider` evaluates Chebyshev polynomials directly from binary Double Precision Array Files (DAF/SPK)
/// using pure Swift and Apple Accelerate SIMD operations via ``SPKReader``.
///
/// It supports all major Solar System bodies in the ICRS/J2000 reference frame with heliocentric coordinates:
/// - Sun, Mercury, Venus, Earth, Moon, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto.
///
/// All positions are returned in **AU** and velocities in **AU/day**.
public final class SPKEphemerisProvider: EphemerisProvider, Sendable {

    // MARK: - Constants

    /// Astronomical Unit in kilometers (IAU 2012 exact definition).
    public static let kmPerAU: Double = 149_597_870.700

    /// Seconds in one standard day.
    public static let secondsPerDay: Double = 86400.0

    /// Earth-Moon mass ratio: μ = M_Moon / (M_Earth + M_Moon) = 1 / (1 + 81.30056907).
    private static let moonMassRatio: Double = 1.0 / (1.0 + 81.30056907)

    // MARK: - Properties

    /// The underlying SPK reader.
    public let spkReader: SPKReader

    /// The URL of the loaded kernel file.
    public let fileURL: URL

    /// The overall valid start epoch in seconds past J2000 TDB.
    public let startEpochTDB: Double

    /// The overall valid end epoch in seconds past J2000 TDB.
    public let endEpochTDB: Double

    // MARK: - Initialization

    /// Initializes a provider from a local SPK/BSP file URL.
    ///
    /// - Parameter spkFileURL: Local URL of the SPK binary kernel (e.g. `de442s.bsp`, `inpop21a.bsp`, or `epm2021.bsp`).
    /// - Throws: ``EphemerisError/dataFileNotFound(_:)`` if the file doesn't exist,
    ///           or ``EphemerisError/dataCorrupted(_:)`` if parsing fails.
    public init(spkFileURL: URL) throws {
        self.fileURL = spkFileURL
        self.spkReader = try SPKReader(url: spkFileURL)

        guard !spkReader.segments.isEmpty else {
            throw EphemerisError.dataCorrupted("SPK kernel contains no segments: \(spkFileURL.lastPathComponent)")
        }

        // Determine conservative common coverage across planetary segments
        var minEpoch = -Double.greatestFiniteMagnitude
        var maxEpoch = Double.greatestFiniteMagnitude

        // Filter primary planetary segments (center 0) to establish baseline coverage
        let primarySegments = spkReader.segments.filter { $0.centerID == 0 && $0.dataType == 2 }
        if !primarySegments.isEmpty {
            minEpoch = primarySegments.map(\.startEpoch).max() ?? primarySegments[0].startEpoch
            maxEpoch = primarySegments.map(\.endEpoch).min() ?? primarySegments[0].endEpoch
        } else {
            minEpoch = spkReader.segments.map(\.startEpoch).min() ?? 0
            maxEpoch = spkReader.segments.map(\.endEpoch).max() ?? 0
        }

        self.startEpochTDB = minEpoch
        self.endEpochTDB = maxEpoch
    }

    // MARK: - EphemerisProvider Conformance

    /// Heliocentric position of a Solar System body in AU (ICRS/J2000).
    public func position(for body: SolarSystemBody, at jd: JulianDay) throws -> Vector3D {
        if body == .sun {
            return .zero
        }
        let sv = try stateVector(for: body, at: jd)
        return sv.position
    }

    /// Full 6D state vector (position in AU, velocity in AU/day) of a Solar System body (ICRS/J2000).
    public func stateVector(for body: SolarSystemBody, at jd: JulianDay) throws -> StateVector {
        if body == .sun {
            return StateVector(position: .zero, velocity: .zero)
        }

        let epochTDB = SPKReader.julianDayToTDBSeconds(jd.value)
        guard epochTDB >= startEpochTDB && epochTDB <= endEpochTDB else {
            throw EphemerisError.dateOutOfRange(jd)
        }

        let bodyStateSSB = try evaluateBodyRelSSB(body: body, epochTDB: epochTDB)
        let sunStateSSB = try evaluateSunRelSSB(epochTDB: epochTDB)

        let helioPosKm = bodyStateSSB.position - sunStateSSB.position
        let helioVelKmS = bodyStateSSB.velocity - sunStateSSB.velocity

        let posAU = helioPosKm / Self.kmPerAU
        let velAUPerDay = helioVelKmS * (Self.secondsPerDay / Self.kmPerAU)

        return StateVector(position: posAU, velocity: velAUPerDay)
    }

    // MARK: - Private Evaluation Chain

    /// Candidate NAIF target IDs for each SolarSystemBody.
    private func candidateNAIFTargetIDs(for body: SolarSystemBody) -> [Int32] {
        switch body {
        case .sun: return [10]
        case .mercury: return [199, 1]
        case .venus: return [299, 2]
        case .earth: return [399, 3]
        case .moon: return [301]
        case .mars: return [499, 4]
        case .jupiter: return [599, 5]
        case .saturn: return [699, 6]
        case .uranus: return [799, 7]
        case .neptune: return [899, 8]
        case .pluto: return [999, 9]
        }
    }

    /// Evaluates the state vector of a body relative to the Solar System Barycenter (SSB = 0) in km and km/s.
    private func evaluateBodyRelSSB(body: SolarSystemBody, epochTDB: Double) throws -> SPKReader.EvaluationResult {
        // Special Moon case: evaluate relative to EMB (3) or Earth (399)
        if body == .moon {
            if let moonSeg = spkReader.segments.last(where: {
                $0.targetID == 301 && epochTDB >= $0.startEpoch && epochTDB <= $0.endEpoch
            }) {
                let moonResult = try spkReader.evaluate(segment: moonSeg, epochTDB: epochTDB)
                let centerSSB = try resolveTargetRelSSB(targetID: moonSeg.centerID, epochTDB: epochTDB, depth: 0)
                return SPKReader.EvaluationResult(
                    position: centerSSB.position + moonResult.position,
                    velocity: centerSSB.velocity + moonResult.velocity
                )
            }
            throw EphemerisError.bodyNotSupported(body)
        }

        // Special Earth case: if 399 segment doesn't exist, derive from EMB (3) and Moon (301)
        if body == .earth {
            if let earthSeg = spkReader.segments.last(where: {
                $0.targetID == 399 && epochTDB >= $0.startEpoch && epochTDB <= $0.endEpoch
            }) {
                let earthResult = try spkReader.evaluate(segment: earthSeg, epochTDB: epochTDB)
                let centerSSB = try resolveTargetRelSSB(targetID: earthSeg.centerID, epochTDB: epochTDB, depth: 0)
                return SPKReader.EvaluationResult(
                    position: centerSSB.position + earthResult.position,
                    velocity: centerSSB.velocity + earthResult.velocity
                )
            } else if let embSeg = spkReader.segments.last(where: {
                $0.targetID == 3 && epochTDB >= $0.startEpoch && epochTDB <= $0.endEpoch
            }) {
                let embResult = try spkReader.evaluate(segment: embSeg, epochTDB: epochTDB)
                let embSSB = embSeg.centerID == 0 ? embResult : try {
                    let c = try resolveTargetRelSSB(targetID: embSeg.centerID, epochTDB: epochTDB, depth: 0)
                    return SPKReader.EvaluationResult(position: c.position + embResult.position, velocity: c.velocity + embResult.velocity)
                }()

                // Offset Earth from EMB using Moon:
                // If segment center is EMB (3): r_Earth/EMB = - (M_Moon / M_Earth) * r_Moon/EMB = - (1 / 81.30056907) * r_Moon/EMB
                // If segment center is Earth (399): r_Earth/EMB = - μ * r_Moon/Earth
                if let moonSeg = spkReader.segments.last(where: {
                    $0.targetID == 301 && ($0.centerID == 3 || $0.centerID == 399) && epochTDB >= $0.startEpoch && epochTDB <= $0.endEpoch
                }) {
                    let moonResult = try spkReader.evaluate(segment: moonSeg, epochTDB: epochTDB)
                    let ratio = (moonSeg.centerID == 3) ? (1.0 / 81.30056907) : Self.moonMassRatio
                    let offsetPos = moonResult.position * (-ratio)
                    let offsetVel = moonResult.velocity * (-ratio)
                    return SPKReader.EvaluationResult(
                        position: embSSB.position + offsetPos,
                        velocity: embSSB.velocity + offsetVel
                    )
                }
                // Fallback to EMB if Moon sub-segment is missing
                return embSSB
            }
        }

        // General bodies: try candidate NAIF IDs
        let candidates = candidateNAIFTargetIDs(for: body)
        for candID in candidates {
            if let seg = spkReader.segments.last(where: {
                $0.targetID == candID && epochTDB >= $0.startEpoch && epochTDB <= $0.endEpoch
            }) {
                let segResult = try spkReader.evaluate(segment: seg, epochTDB: epochTDB)
                if seg.centerID == 0 {
                    return segResult
                }
                let centerSSB = try resolveTargetRelSSB(targetID: seg.centerID, epochTDB: epochTDB, depth: 0)
                return SPKReader.EvaluationResult(
                    position: centerSSB.position + segResult.position,
                    velocity: centerSSB.velocity + segResult.velocity
                )
            }
        }

        throw EphemerisError.bodyNotSupported(body)
    }

    /// Evaluates the state vector of the Sun relative to SSB (0) in km and km/s.
    private func evaluateSunRelSSB(epochTDB: Double) throws -> SPKReader.EvaluationResult {
        if let sunSeg = spkReader.segments.last(where: {
            $0.targetID == 10 && $0.centerID == 0 && epochTDB >= $0.startEpoch && epochTDB <= $0.endEpoch
        }) {
            return try spkReader.evaluate(segment: sunSeg, epochTDB: epochTDB)
        }
        // If Sun segment is absent, standard origin is assumed at the Sun
        return SPKReader.EvaluationResult(position: .zero, velocity: .zero)
    }

    /// Resolves target position relative to SSB (0) through parent segments recursively.
    private func resolveTargetRelSSB(targetID: Int32, epochTDB: Double, depth: Int) throws -> SPKReader.EvaluationResult {
        if targetID == 0 {
            return SPKReader.EvaluationResult(position: .zero, velocity: .zero)
        }
        guard depth < 10 else {
            throw EphemerisError.dataCorrupted("Exceeded maximum recursion depth resolving SPK target \(targetID)")
        }

        if let seg = spkReader.segments.last(where: {
            $0.targetID == targetID && epochTDB >= $0.startEpoch && epochTDB <= $0.endEpoch
        }) {
            let segRes = try spkReader.evaluate(segment: seg, epochTDB: epochTDB)
            if seg.centerID == 0 {
                return segRes
            }
            let centerRes = try resolveTargetRelSSB(targetID: seg.centerID, epochTDB: epochTDB, depth: depth + 1)
            return SPKReader.EvaluationResult(
                position: centerRes.position + segRes.position,
                velocity: centerRes.velocity + segRes.velocity
            )
        }

        throw EphemerisError.dataCorrupted("Could not resolve SPK parent chain for target \(targetID)")
    }
}
