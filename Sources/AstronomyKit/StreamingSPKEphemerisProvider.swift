//
//  StreamingSPKEphemerisProvider.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

import Foundation

/// Ephemeris provider evaluating planetary positions via Dynamic Temporal Streaming over HTTP.
///
/// Instead of downloading the full kernel, this provider downloads only the active Chebyshev record
/// slice on demand, reducing network data consumption by over 99.9%.
public final class StreamingSPKEphemerisProvider: Sendable {

    // MARK: - Constants

    public static let kmPerAU: Double = 149_597_870.700
    public static let secondsPerDay: Double = 86400.0
    private static let moonMassRatio: Double = 1.0 / (1.0 + 81.30056907)

    // MARK: - Properties

    /// The ephemeris dataset being streamed, if initialized with one.
    public let dataset: EphemerisDataset?

    /// The underlying streaming reader.
    public let reader: StreamingSPKReader

    // MARK: - Initialization

    /// Initializes a streaming provider with a `StreamingSPKReader` and optional dataset metadata.
    public init(dataset: EphemerisDataset? = nil, reader: StreamingSPKReader) {
        self.dataset = dataset
        self.reader = reader
    }

    /// Convenience initializer for a dataset.
    public init(
        dataset: EphemerisDataset,
        cacheDirectory: URL
    ) {
        self.dataset = dataset
        let datasetCacheDir = cacheDirectory.appendingPathComponent("streaming_\(dataset.rawValue)")
        let client = SPKRangeClient(
            primaryURL: dataset.remoteURL,
            fallbackURL: dataset.fallbackRemoteURL,
            cacheDirectory: datasetCacheDir
        )
        self.reader = StreamingSPKReader(client: client)
    }

    // MARK: - Public Streaming API

    /// Evaluates the heliocentric position of a body in AU (ICRS/J2000) via streaming.
    public func position(for body: SolarSystemBody, at jd: JulianDay) async throws -> Vector3D {
        if body == .sun { return .zero }
        let sv = try await stateVector(for: body, at: jd)
        return sv.position
    }

    /// Evaluates the full 6D state vector (position in AU, velocity in AU/day) via streaming.
    public func stateVector(for body: SolarSystemBody, at jd: JulianDay) async throws -> StateVector {
        if body == .sun {
            return StateVector(position: .zero, velocity: .zero)
        }

        let epochTDB = SPKReader.julianDayToTDBSeconds(jd.value)
        let bodySSB = try await evaluateBodyRelSSB(body: body, epochTDB: epochTDB)
        let sunSSB = try await evaluateSunRelSSB(epochTDB: epochTDB)

        let helioPosKm = bodySSB.position - sunSSB.position
        let helioVelKmS = bodySSB.velocity - sunSSB.velocity

        let posAU = helioPosKm / Self.kmPerAU
        let velAUPerDay = helioVelKmS * (Self.secondsPerDay / Self.kmPerAU)

        return StateVector(position: posAU, velocity: velAUPerDay)
    }

    /// Geocentric position of the Moon in AU (ICRS/J2000, TDB) via dynamic HTTP streaming.
    public func lunarGeocentricPosition(at jd: JulianDay) async throws -> Vector3D {
        let moonHelio = try await position(for: .moon, at: jd)
        let earthHelio = try await position(for: .earth, at: jd)
        return moonHelio - earthHelio
    }

    /// Geocentric 6D state vector of the Moon (position in AU, velocity in AU/day) via dynamic HTTP streaming.
    public func lunarGeocentricStateVector(at jd: JulianDay) async throws -> StateVector {
        let moonState = try await stateVector(for: .moon, at: jd)
        let earthState = try await stateVector(for: .earth, at: jd)
        return StateVector(
            position: moonState.position - earthState.position,
            velocity: moonState.velocity - earthState.velocity
        )
    }

    // MARK: - Target Resolution

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

    private func evaluateBodyRelSSB(body: SolarSystemBody, epochTDB: Double) async throws -> SPKReader.EvaluationResult {
        let segs = try await reader.getSegments()

        // Special Moon case
        if body == .moon {
            if let moonSeg = segs.last(where: {
                $0.targetID == 301 && epochTDB >= $0.startEpoch && epochTDB <= $0.endEpoch
            }) {
                let moonResult = try await reader.evaluate(segment: moonSeg, epochTDB: epochTDB)
                let centerSSB = try await resolveTargetRelSSB(targetID: moonSeg.centerID, epochTDB: epochTDB, depth: 0)
                return SPKReader.EvaluationResult(
                    position: centerSSB.position + moonResult.position,
                    velocity: centerSSB.velocity + moonResult.velocity
                )
            }
            throw EphemerisError.bodyNotSupported(body)
        }

        // Special Earth case
        if body == .earth {
            if let earthSeg = segs.last(where: {
                $0.targetID == 399 && epochTDB >= $0.startEpoch && epochTDB <= $0.endEpoch
            }) {
                let earthResult = try await reader.evaluate(segment: earthSeg, epochTDB: epochTDB)
                let centerSSB = try await resolveTargetRelSSB(targetID: earthSeg.centerID, epochTDB: epochTDB, depth: 0)
                return SPKReader.EvaluationResult(
                    position: centerSSB.position + earthResult.position,
                    velocity: centerSSB.velocity + earthResult.velocity
                )
            } else if let embSeg = segs.last(where: {
                $0.targetID == 3 && epochTDB >= $0.startEpoch && epochTDB <= $0.endEpoch
            }) {
                let embResult = try await reader.evaluate(segment: embSeg, epochTDB: epochTDB)
                let embSSB = embSeg.centerID == 0 ? embResult : try await {
                    let c = try await resolveTargetRelSSB(targetID: embSeg.centerID, epochTDB: epochTDB, depth: 0)
                    return SPKReader.EvaluationResult(position: c.position + embResult.position, velocity: c.velocity + embResult.velocity)
                }()

                if let moonSeg = segs.last(where: {
                    $0.targetID == 301 && ($0.centerID == 3 || $0.centerID == 399) && epochTDB >= $0.startEpoch && epochTDB <= $0.endEpoch
                }) {
                    let moonResult = try await reader.evaluate(segment: moonSeg, epochTDB: epochTDB)
                    let ratio = (moonSeg.centerID == 3) ? (1.0 / 81.30056907) : Self.moonMassRatio
                    let offsetPos = moonResult.position * (-ratio)
                    let offsetVel = moonResult.velocity * (-ratio)
                    return SPKReader.EvaluationResult(
                        position: embSSB.position + offsetPos,
                        velocity: embSSB.velocity + offsetVel
                    )
                }
                return embSSB
            }
        }

        // General bodies
        let candidates = candidateNAIFTargetIDs(for: body)
        for candID in candidates {
            if let seg = segs.last(where: {
                $0.targetID == candID && epochTDB >= $0.startEpoch && epochTDB <= $0.endEpoch
            }) {
                let segResult = try await reader.evaluate(segment: seg, epochTDB: epochTDB)
                if seg.centerID == 0 {
                    return segResult
                }
                let centerSSB = try await resolveTargetRelSSB(targetID: seg.centerID, epochTDB: epochTDB, depth: 0)
                return SPKReader.EvaluationResult(
                    position: centerSSB.position + segResult.position,
                    velocity: centerSSB.velocity + segResult.velocity
                )
            }
        }

        throw EphemerisError.bodyNotSupported(body)
    }

    private func evaluateSunRelSSB(epochTDB: Double) async throws -> SPKReader.EvaluationResult {
        let segs = try await reader.getSegments()
        if let sunSeg = segs.last(where: {
            $0.targetID == 10 && $0.centerID == 0 && epochTDB >= $0.startEpoch && epochTDB <= $0.endEpoch
        }) {
            return try await reader.evaluate(segment: sunSeg, epochTDB: epochTDB)
        }
        return SPKReader.EvaluationResult(position: .zero, velocity: .zero)
    }

    private func resolveTargetRelSSB(targetID: Int32, epochTDB: Double, depth: Int) async throws -> SPKReader.EvaluationResult {
        if targetID == 0 {
            return SPKReader.EvaluationResult(position: .zero, velocity: .zero)
        }
        guard depth < 10 else {
            throw EphemerisError.dataCorrupted("Exceeded maximum recursion depth resolving SPK target \(targetID)")
        }

        let segs = try await reader.getSegments()
        if let seg = segs.last(where: {
            $0.targetID == targetID && epochTDB >= $0.startEpoch && epochTDB <= $0.endEpoch
        }) {
            let segRes = try await reader.evaluate(segment: seg, epochTDB: epochTDB)
            if seg.centerID == 0 {
                return segRes
            }
            let centerRes = try await resolveTargetRelSSB(targetID: seg.centerID, epochTDB: epochTDB, depth: depth + 1)
            return SPKReader.EvaluationResult(
                position: centerRes.position + segRes.position,
                velocity: centerRes.velocity + segRes.velocity
            )
        }

        throw EphemerisError.dataCorrupted("Could not resolve SPK parent chain for target \(targetID)")
    }
}
