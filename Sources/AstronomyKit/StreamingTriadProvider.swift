//
//  StreamingTriadProvider.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

import Foundation

/// Semantic alias for 4-agency streaming ensemble provider (Tetrad).
public typealias StreamingTetradProvider = StreamingTriadProvider

/// Orchestrates the Triad / Tetrad numerical ensemble (US + FR + RU + CN) in Dynamic Temporal Streaming mode.
///
/// Fetches only the required byte-range chunks in parallel for NASA JPL DE442s, IMCCE INPOP21a,
/// IAA RAS EPM2021, and PMO/CAS PMOE, and combines them into a consensus state vector with 1-sigma physical uncertainty.
public final class StreamingTriadProvider: Sendable {

    // MARK: - Constants

    public static let kmPerAU: Double = 149_597_870.700
    private static let arcsecPerRadian: Double = 206_264.806247096355

    // MARK: - Properties

    /// Active streaming providers keyed by contributing agency.
    public let providers: [TriadAgency: StreamingSPKEphemerisProvider]

    // MARK: - Initialization

    /// Initializes a streaming Triad/Tetrad provider with an explicit map of agency streaming providers.
    public init(providers: [TriadAgency: StreamingSPKEphemerisProvider]) throws {
        guard !providers.isEmpty else {
            throw EphemerisError.dataFileNotFound(
                "StreamingTriadProvider requires at least one streaming numerical provider (US, FR, RU, or CN)."
            )
        }
        self.providers = providers
    }

    /// Convenience initializer accepting individual optional streaming providers.
    public convenience init(
        us: StreamingSPKEphemerisProvider? = nil,
        fr: StreamingSPKEphemerisProvider? = nil,
        ru: StreamingSPKEphemerisProvider? = nil,
        cn: StreamingSPKEphemerisProvider? = nil
    ) throws {
        var map: [TriadAgency: StreamingSPKEphemerisProvider] = [:]
        if let us { map[.us] = us }
        if let fr { map[.fr] = fr }
        if let ru { map[.ru] = ru }
        if let cn { map[.cn] = cn }
        try self.init(providers: map)
    }

    /// Convenience initializer from cache directory.
    public init(
        cacheDirectory: URL,
        datasets: [EphemerisDataset] = [.de442, .inpop21a, .epm2021, .pmoe]
    ) throws {
        var map: [TriadAgency: StreamingSPKEphemerisProvider] = [:]
        for ds in datasets {
            let sp = StreamingSPKEphemerisProvider(dataset: ds, cacheDirectory: cacheDirectory)
            switch ds {
            case .de442s, .de442: map[.us] = sp
            case .inpop21a: map[.fr] = sp
            case .epm2021: map[.ru] = sp
            case .pmoe: map[.cn] = sp
            default: break
            }
        }
        guard !map.isEmpty else {
            throw EphemerisError.dataFileNotFound("No streaming datasets provided for StreamingTriadProvider.")
        }
        self.providers = map
    }

    // MARK: - Parallel Streaming Consensus

    /// Computes multi-agency consensus and physical uncertainty by streaming chunks in parallel.
    ///
    /// Total bandwidth consumed: $< 10\,\text{KB}$ for all three models combined.
    public func consensusDetails(for body: SolarSystemBody, at jd: JulianDay) async throws -> TriadConsensusDetails {
        if body == .sun {
            let active = Array(providers.keys).sorted(by: { $0.rawValue < $1.rawValue })
            var posMap: [TriadAgency: Vector3D] = [:]
            var velMap: [TriadAgency: Vector3D] = [:]
            for a in active {
                posMap[a] = .zero
                velMap[a] = .zero
            }
            return TriadConsensusDetails(
                body: .sun,
                julianDay: jd,
                consensusPosition: .zero,
                consensusVelocity: .zero,
                physicalUncertaintyKm: 0.0,
                physicalUncertaintyArcsec: 0.0,
                maxDiscrepancyKm: 0.0,
                agencyPositions: posMap,
                agencyVelocities: velMap,
                contributingAgencies: active
            )
        }

        // Fetch state vectors in parallel across agencies
        let results = await withTaskGroup(of: (TriadAgency, Result<StateVector, Error>).self) { group in
            for (agency, provider) in providers {
                group.addTask {
                    do {
                        let sv = try await provider.stateVector(for: body, at: jd)
                        return (agency, .success(sv))
                    } catch {
                        return (agency, .failure(error))
                    }
                }
            }

            var evaluated: [TriadAgency: StateVector] = [:]
            for await (agency, outcome) in group {
                if case .success(let sv) = outcome {
                    evaluated[agency] = sv
                }
            }
            return evaluated
        }

        guard !results.isEmpty else {
            throw EphemerisError.calculationFailed(
                "All streaming providers failed to evaluate \(body.name) at JD \(jd.value)."
            )
        }

        let contributing = Array(results.keys).sorted(by: { $0.rawValue < $1.rawValue })
        let count = Double(contributing.count)

        var sumPos = Vector3D.zero
        var sumVel = Vector3D.zero
        var positions: [TriadAgency: Vector3D] = [:]
        var velocities: [TriadAgency: Vector3D] = [:]

        for agency in contributing {
            let sv = results[agency]!
            positions[agency] = sv.position
            velocities[agency] = sv.velocity
            sumPos = sumPos + sv.position
            sumVel = sumVel + sv.velocity
        }

        let meanPos = sumPos / count
        let meanVel = sumVel / count

        // Compute 1-sigma uncertainty and maximum pairwise discrepancy
        var uncertaintyKm: Double = 0.0
        var maxDiscrepancyKm: Double = 0.0

        if contributing.count > 1 {
            var sumSquaredDevKm2: Double = 0.0
            for agency in contributing {
                let diffKm = (positions[agency]! - meanPos) * Self.kmPerAU
                sumSquaredDevKm2 += diffKm.lengthSquared
            }
            let variance = sumSquaredDevKm2 / Double(contributing.count - 1)
            uncertaintyKm = sqrt(variance)

            for i in 0..<contributing.count {
                for j in (i + 1)..<contributing.count {
                    let p1 = positions[contributing[i]]!
                    let p2 = positions[contributing[j]]!
                    let distKm = (p1 - p2).length * Self.kmPerAU
                    if distKm > maxDiscrepancyKm {
                        maxDiscrepancyKm = distKm
                    }
                }
            }
        }

        // Angular uncertainty in arcseconds
        var uncertaintyArcsec: Double = 0.0
        if uncertaintyKm > 0 && body != .earth {
            let earthPos = (try? await evaluateEarthPosition(at: jd)) ?? meanPos
            let geocentricDistKm = (meanPos - earthPos).length * Self.kmPerAU
            if geocentricDistKm > 0 {
                let rad = uncertaintyKm / geocentricDistKm
                uncertaintyArcsec = rad * Self.arcsecPerRadian
            }
        }

        return TriadConsensusDetails(
            body: body,
            julianDay: jd,
            consensusPosition: meanPos,
            consensusVelocity: meanVel,
            physicalUncertaintyKm: uncertaintyKm,
            physicalUncertaintyArcsec: uncertaintyArcsec,
            maxDiscrepancyKm: maxDiscrepancyKm,
            agencyPositions: positions,
            agencyVelocities: velocities,
            contributingAgencies: contributing
        )
    }

    /// Helper evaluating Earth's consensus position for angular projection.
    private func evaluateEarthPosition(at jd: JulianDay) async throws -> Vector3D {
        for provider in providers.values {
            if let pos = try? await provider.position(for: .earth, at: jd) {
                return pos
            }
        }
        throw EphemerisError.calculationFailed("Could not resolve Earth position for angular projection")
    }

    // MARK: - Convenience Evaluation APIs

    /// Heliocentric position of a Solar System body in AU (ICRS/J2000) computed via streaming consensus.
    public func position(for body: SolarSystemBody, at jd: JulianDay) async throws -> Vector3D {
        let details = try await consensusDetails(for: body, at: jd)
        return details.consensusPosition
    }

    /// Full 6D state vector of a Solar System body (position in AU, velocity in AU/day) computed via streaming consensus.
    public func stateVector(for body: SolarSystemBody, at jd: JulianDay) async throws -> StateVector {
        let details = try await consensusDetails(for: body, at: jd)
        return StateVector(position: details.consensusPosition, velocity: details.consensusVelocity)
    }

    /// Geocentric position of the Moon in AU (ICRS/J2000, TDB) computed via streaming consensus.
    public func lunarGeocentricPosition(at jd: JulianDay) async throws -> Vector3D {
        let moonPos = try await position(for: .moon, at: jd)
        let earthPos = try await position(for: .earth, at: jd)
        return moonPos - earthPos
    }

    /// Geocentric 6D state vector of the Moon (position in AU, velocity in AU/day) computed via streaming consensus.
    public func lunarGeocentricStateVector(at jd: JulianDay) async throws -> StateVector {
        let moonState = try await stateVector(for: .moon, at: jd)
        let earthState = try await stateVector(for: .earth, at: jd)
        return StateVector(
            position: moonState.position - earthState.position,
            velocity: moonState.velocity - earthState.velocity
        )
    }
}
