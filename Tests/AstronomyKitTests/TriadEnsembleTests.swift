//
//  TriadEnsembleTests.swift
//  AstronomyKitTests
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

import Testing
import Foundation
@testable import AstronomyKit

@Suite("Triad Ensemble & Numerical Exclusivity")
struct TriadEnsembleTests {

    // MARK: - Mock Provider for Metrological Testing

    private struct MockNumericalProvider: EphemerisProvider, Sendable {
        let positionOffsetAU: Vector3D
        let velocityOffsetAUPerDay: Vector3D

        func position(for body: SolarSystemBody, at jd: JulianDay) throws -> Vector3D {
            if body == .sun { return .zero }
            return Vector3D(x: 1.0, y: 0.0, z: 0.0) + positionOffsetAU
        }

        func stateVector(for body: SolarSystemBody, at jd: JulianDay) throws -> StateVector {
            if body == .sun { return StateVector(position: .zero, velocity: .zero) }
            return StateVector(
                position: Vector3D(x: 1.0, y: 0.0, z: 0.0) + positionOffsetAU,
                velocity: Vector3D(x: 0.0, y: 0.0172, z: 0.0) + velocityOffsetAUPerDay
            )
        }
    }

    private struct FailingNumericalProvider: EphemerisProvider, Sendable {
        func position(for body: SolarSystemBody, at jd: JulianDay) throws -> Vector3D {
            throw EphemerisError.dateOutOfRange(jd)
        }

        func stateVector(for body: SolarSystemBody, at jd: JulianDay) throws -> StateVector {
            throw EphemerisError.dateOutOfRange(jd)
        }
    }

    // MARK: - Dataset & Agency Metadata Tests

    @Test("Triad and Tetrad agency metadata and dataset mappings")
    func agencyMetadata() {
        #expect(TriadAgency.allCases.count == 4)

        let us = TriadAgency.us
        #expect(us.rawValue == "US")
        #expect(us.dataset == .de442)
        #expect(us.institutionName.contains("NASA"))

        let fr = TriadAgency.fr
        #expect(fr.rawValue == "FR")
        #expect(fr.dataset == .inpop21a)
        #expect(fr.institutionName.contains("IMCCE"))

        let ru = TriadAgency.ru
        #expect(ru.rawValue == "RU")
        #expect(ru.dataset == .epm2021)
        #expect(ru.institutionName.contains("IAA RAS"))

        let cn = TriadAgency.cn
        #expect(cn.rawValue == "CN")
        #expect(cn.dataset == .pmoe)
        #expect(cn.institutionName.contains("Purple Mountain Observatory"))

        // Verify semantic alias
        #expect(EnsembleAgency.cn == TriadAgency.cn)
    }

    @Test("Triad and Tetrad datasets have canonical GitHub Releases URLs and upstream fallback")
    func triadDatasetURLs() {
        let de442 = EphemerisDataset.de442
        #expect(de442.filename == "de442.bsp")
        #expect(de442.remoteURL.absoluteString.contains("naif.jpl.nasa.gov") == true)
        #expect(de442.fallbackRemoteURL?.absoluteString.contains("github.com/momolas/CALMSKY") == true)

        let de442s = EphemerisDataset.de442s
        #expect(de442s.filename == "de442s.bsp")
        // de442s primary source is the canonical GitHub Releases CDN (same policy as inpop21a, epm2021, pmoe)
        #expect(de442s.remoteURL.absoluteString.hasPrefix("https://github.com/momolas/CALMSKY/releases/download/ephemerides-v1.0/"))
        // Fallback is NASA NAIF official server
        #expect(de442s.fallbackRemoteURL?.absoluteString.contains("naif.jpl.nasa.gov") == true)


        let inpop21a = EphemerisDataset.inpop21a
        #expect(inpop21a.filename == "inpop21a.bsp")
        #expect(inpop21a.remoteURL.absoluteString.hasPrefix("https://github.com/momolas/CALMSKY/releases/download/ephemerides-v1.0/"))
        #expect(inpop21a.fallbackRemoteURL?.absoluteString.contains("imcce.fr") == true)

        let epm2021 = EphemerisDataset.epm2021
        #expect(epm2021.filename == "epm2021.bsp")
        #expect(epm2021.remoteURL.absoluteString.hasPrefix("https://github.com/momolas/CALMSKY/releases/download/ephemerides-v1.0/"))
        #expect(epm2021.fallbackRemoteURL?.absoluteString.contains("iaaras.ru") == true)

        let pmoe = EphemerisDataset.pmoe
        #expect(pmoe.filename == "pmoe.bsp")
        #expect(pmoe.remoteURL.absoluteString.hasPrefix("https://github.com/momolas/CALMSKY/releases/download/ephemerides-v1.0/"))
        #expect(pmoe.fallbackRemoteURL?.absoluteString.contains("pmo.cas.cn") == true)
    }

    // MARK: - Initialization & Numerical Exclusivity

    @Test("TriadEphemerisProvider requires at least one numerical provider")
    func providerInitializationExclusivity() {
        #expect(throws: EphemerisError.self) {
            _ = try TriadEphemerisProvider(providers: [:])
        }

        #expect(throws: EphemerisError.self) {
            _ = try TriadEphemerisProvider(us: nil, fr: nil, ru: nil)
        }
    }

    @Test("TriadEphemerisProvider throws when all underlying numerical models fail (no analytical fallback)")
    func strictNumericalExclusivityOnFailure() throws {
        let failing = FailingNumericalProvider()
        let triad = try TriadEphemerisProvider(us: failing, fr: failing, ru: failing)

        let jd = JulianDay(2451545.0)
        #expect(throws: EphemerisError.self) {
            _ = try triad.position(for: .mars, at: jd)
        }
        #expect(throws: EphemerisError.self) {
            _ = try triad.stateVector(for: .mars, at: jd)
        }
    }

    // MARK: - Metrological Consensus & Physical Uncertainty

    @Test("Triad computes exact consensus position and 1-sigma physical uncertainty")
    func consensusAndUncertaintyComputation() throws {
        let deltaAU = 0.00001 // ≈ 1495.98 km offset
        let deltaKm = deltaAU * TriadEphemerisProvider.kmPerAU

        let usProvider = MockNumericalProvider(
            positionOffsetAU: Vector3D(x: 0.0, y: 0.0, z: 0.0),
            velocityOffsetAUPerDay: .zero
        )
        let frProvider = MockNumericalProvider(
            positionOffsetAU: Vector3D(x: deltaAU, y: 0.0, z: 0.0),
            velocityOffsetAUPerDay: .zero
        )
        let ruProvider = MockNumericalProvider(
            positionOffsetAU: Vector3D(x: -deltaAU, y: 0.0, z: 0.0),
            velocityOffsetAUPerDay: .zero
        )

        let triad = try TriadEphemerisProvider(us: usProvider, fr: frProvider, ru: ruProvider)
        let jd = JulianDay(2451545.0)

        let details = try triad.consensusDetails(for: .mars, at: jd)

        // Consensus position should be exactly (1.0, 0.0, 0.0) AU
        #expect(abs(details.consensusPosition.x - 1.0) < 1e-12)
        #expect(abs(details.consensusPosition.y) < 1e-12)
        #expect(abs(details.consensusPosition.z) < 1e-12)

        // Contributing agencies should contain US, FR, RU
        #expect(details.contributingAgencies.count == 3)
        #expect(details.contributingAgencies.contains(.us))
        #expect(details.contributingAgencies.contains(.fr))
        #expect(details.contributingAgencies.contains(.ru))

        // 1-sigma uncertainty for offsets [0, +delta, -delta] with N=3:
        // Variance = (0^2 + delta^2 + (-delta)^2) / (3 - 1) = delta^2
        // Standard deviation = deltaKm
        #expect(abs(details.physicalUncertaintyKm - deltaKm) < 1e-6)

        // Maximum discrepancy should be 2 * deltaKm
        let expectedMaxDiscrepancy = 2.0 * deltaKm
        #expect(abs(details.maxDiscrepancyKm - expectedMaxDiscrepancy) < 1e-6)

        // Standard EphemerisProvider position returns the consensus position
        let pos = try triad.position(for: .mars, at: jd)
        #expect(pos == details.consensusPosition)

        // State vector returns consensus position and velocity
        let sv = try triad.stateVector(for: .mars, at: jd)
        #expect(sv.position == details.consensusPosition)
        #expect(sv.velocity == details.consensusVelocity)
    }

    @Test("Tetrad computes exact consensus position and 1-sigma physical uncertainty across 4 agencies (US, FR, RU, CN)")
    func tetradConsensusAndUncertaintyComputation() throws {
        let deltaAU = 0.00001 // ≈ 1495.98 km offset
        let deltaKm = deltaAU * TriadEphemerisProvider.kmPerAU

        let usProvider = MockNumericalProvider(
            positionOffsetAU: Vector3D(x: deltaAU, y: 0.0, z: 0.0),
            velocityOffsetAUPerDay: .zero
        )
        let frProvider = MockNumericalProvider(
            positionOffsetAU: Vector3D(x: -deltaAU, y: 0.0, z: 0.0),
            velocityOffsetAUPerDay: .zero
        )
        let ruProvider = MockNumericalProvider(
            positionOffsetAU: Vector3D(x: 0.0, y: deltaAU, z: 0.0),
            velocityOffsetAUPerDay: .zero
        )
        let cnProvider = MockNumericalProvider(
            positionOffsetAU: Vector3D(x: 0.0, y: -deltaAU, z: 0.0),
            velocityOffsetAUPerDay: .zero
        )

        let tetrad: TetradEphemerisProvider = try TetradEphemerisProvider(
            us: usProvider,
            fr: frProvider,
            ru: ruProvider,
            cn: cnProvider
        )
        let jd = JulianDay(2451545.0)

        let details: TetradConsensusDetails = try tetrad.consensusDetails(for: .mars, at: jd)

        // Consensus position should be exactly (1.0, 0.0, 0.0) AU
        #expect(abs(details.consensusPosition.x - 1.0) < 1e-12)
        #expect(abs(details.consensusPosition.y) < 1e-12)
        #expect(abs(details.consensusPosition.z) < 1e-12)

        // All 4 agencies contributing
        #expect(details.contributingAgencies.count == 4)
        #expect(details.contributingAgencies.contains(.us))
        #expect(details.contributingAgencies.contains(.fr))
        #expect(details.contributingAgencies.contains(.ru))
        #expect(details.contributingAgencies.contains(.cn))

        // 1-sigma uncertainty for 4 orthogonal offsets:
        // Sum of squared deviations = 4 * delta^2
        // Sample variance (N-1=3) = 4/3 * delta^2
        // 1-sigma stddev = 2/sqrt(3) * deltaKm
        let expectedUncertainty = (2.0 / sqrt(3.0)) * deltaKm
        #expect(abs(details.physicalUncertaintyKm - expectedUncertainty) < 1e-6)

        // Maximum pairwise discrepancy among 6 pairs:
        // Max pair is (+delta - (-delta)) along X or Y = 2 * deltaKm
        let expectedMaxDiscrepancy = 2.0 * deltaKm
        #expect(abs(details.maxDiscrepancyKm - expectedMaxDiscrepancy) < 1e-6)

        // EphemerisProvider conformance
        let pos = try tetrad.position(for: .mars, at: jd)
        #expect(pos == details.consensusPosition)

        let sv = try tetrad.stateVector(for: .mars, at: jd)
        #expect(sv.position == details.consensusPosition)
    }

    @Test("Sun evaluation returns zero position, velocity, and zero uncertainty")
    func sunEvaluation() throws {
        let usProvider = MockNumericalProvider(positionOffsetAU: .zero, velocityOffsetAUPerDay: .zero)
        let triad = try TriadEphemerisProvider(us: usProvider)
        let jd = JulianDay(2451545.0)

        let details = try triad.consensusDetails(for: .sun, at: jd)
        #expect(details.consensusPosition == .zero)
        #expect(details.consensusVelocity == .zero)
        #expect(details.physicalUncertaintyKm == 0.0)
        #expect(details.physicalUncertaintyArcsec == 0.0)
        #expect(details.maxDiscrepancyKm == 0.0)
    }

    // MARK: - SPKEphemerisProvider Error Handling

    @Test("SPKEphemerisProvider throws dataFileNotFound on non-existent file")
    func spkFileNotFound() {
        let nonExistentURL = URL(fileURLWithPath: "/tmp/non_existent_kernel_\(UUID().uuidString).bsp")
        #expect(throws: EphemerisError.self) {
            _ = try SPKEphemerisProvider(spkFileURL: nonExistentURL)
        }
    }

    @Test("SPKEphemerisProvider throws dataCorrupted on empty file")
    func spkCorruptedFile() throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("empty_\(UUID().uuidString).bsp")
        try Data().write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        #expect(throws: EphemerisError.self) {
            _ = try SPKEphemerisProvider(spkFileURL: tempURL)
        }
    }

    @Test("INPOP21a and EPM2021 SPK kernels evaluate physical state vectors accurately")
    func realKernelsEvaluation() throws {
        let inpopURL = URL(fileURLWithPath: "/tmp/inpop21a.bsp")
        if FileManager.default.fileExists(atPath: inpopURL.path) {
            let provider = try SPKEphemerisProvider(spkFileURL: inpopURL)
            let jd = JulianDay(2451545.0)
            let earthPos = try provider.position(for: .earth, at: jd)
            #expect(earthPos.length > 0.98 && earthPos.length < 1.02, "INPOP21a Earth distance: \(earthPos.length)")
            let marsPos = try provider.position(for: .mars, at: jd)
            #expect(marsPos.length > 1.38 && marsPos.length < 1.67, "INPOP21a Mars distance: \(marsPos.length)")
            let moonPos = try provider.lunarGeocentricPosition(at: jd)
            let moonDistKm = moonPos.length * SPKEphemerisProvider.kmPerAU
            #expect(moonDistKm > 360_000 && moonDistKm < 406_000, "INPOP21a Moon distance: \(moonDistKm)")

            // Verify secular millennial coverage (1500 CE & 2500 CE)
            let jd1500 = JulianDay(2268923.75) // ~1500 CE
            let earth1500 = try provider.position(for: .earth, at: jd1500)
            #expect(earth1500.length > 0.98 && earth1500.length < 1.02, "INPOP21a Earth distance at 1500 CE: \(earth1500.length)")

            let jd2500 = JulianDay(2634166.25) // ~2500 CE
            let earth2500 = try provider.position(for: .earth, at: jd2500)
            #expect(earth2500.length > 0.98 && earth2500.length < 1.02, "INPOP21a Earth distance at 2500 CE: \(earth2500.length)")
        }

        let epmURL = URL(fileURLWithPath: "/tmp/epm2021.bsp")
        if FileManager.default.fileExists(atPath: epmURL.path) {
            let reader = try SPKReader(url: epmURL)
            #expect(!reader.segments.isEmpty, "EPM2021 kernel should contain parsed segments")
        }
    }
}
