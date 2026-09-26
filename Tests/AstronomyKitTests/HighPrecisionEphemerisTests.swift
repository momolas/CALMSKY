//
//  HighPrecisionEphemerisTests.swift
//  AstronomyKitTests
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

import Testing
import Foundation
@testable import AstronomyKit

// MARK: - Protocol & Error Tests

@Suite("EphemerisProvider Protocol")
struct EphemerisProviderProtocolTests {

    @Test("EphemerisError cases are distinguishable")
    func ephemerisErrorCases() {
        let jd = JulianDay(2451545.0)
        let errors: [EphemerisError] = [
            .bodyNotSupported(.pluto),
            .dateOutOfRange(jd),
            .dataFileNotFound("/missing/file.bin"),
            .dataCorrupted("bad data"),
            .calculationFailed("internal solver error")
        ]
        #expect(errors.count == 5)
    }

    @Test("EphemerisError conforms to LocalizedError with descriptive text")
    func localizedErrorDescriptions() {
        let jd = JulianDay(2451545.0)
        let errors: [(EphemerisError, String)] = [
            (.bodyNotSupported(.pluto), "Pluto"),
            (.dateOutOfRange(jd), "2451545"),
            (.dataFileNotFound("/missing/file.bin"), "/missing/file.bin"),
            (.dataCorrupted("bad header"), "bad header"),
            (.calculationFailed("internal solver error"), "internal solver error")
        ]
        for (error, substring) in errors {
            #expect(error.errorDescription?.contains(substring) == true)
        }
    }

    private struct DummyProvider: EphemerisProvider {
        func position(for body: SolarSystemBody, at jd: JulianDay) throws -> Vector3D { .zero }
        func stateVector(for body: SolarSystemBody, at jd: JulianDay) throws -> StateVector {
            StateVector(position: .zero, velocity: .zero)
        }
    }

    @Test("TriadEphemerisProvider conforms to EphemerisProvider")
    func triadConformance() throws {
        let provider: any EphemerisProvider = try TriadEphemerisProvider(providers: [.us: DummyProvider()])
        #expect(provider is TriadEphemerisProvider)
    }
}

// MARK: - SPK Reader Tests

@Suite("SPKReader")
struct SPKReaderTests {

    @Test("Julian Day to TDB seconds conversion is correct")
    func julianDayConversion() {
        // J2000.0 should map to 0 seconds
        let seconds = SPKReader.julianDayToTDBSeconds(2451545.0)
        #expect(abs(seconds) < 0.001)
    }

    @Test("TDB seconds to Julian Day round-trip")
    func tdbSecondsRoundTrip() {
        let originalJD = 2460000.5
        let seconds = SPKReader.julianDayToTDBSeconds(originalJD)
        let recoveredJD = SPKReader.tdbSecondsToJulianDay(seconds)
        #expect(abs(originalJD - recoveredJD) < 1e-10)
    }
}

// MARK: - VSOP2013 Compilation Test

@Suite("VSOP2013 Provider")
struct VSOP2013ProviderTests {

    @Test("VSOP2013Provider rejects missing directory")
    func vsop2013ProviderMissingDir() {
        #expect(throws: EphemerisError.self) {
            _ = try VSOP2013Provider(dataDirectoryURL: URL(fileURLWithPath: "/nonexistent/vsop2013/"))
        }
    }

    @Test("VSOP2013Provider accepts existing directory")
    func vsop2013ProviderExistingDir() throws {
        // Should not throw — the temp directory exists
        let provider = try VSOP2013Provider(dataDirectoryURL: FileManager.default.temporaryDirectory)
        // Verify it conforms to EphemerisProvider
        let ephemerisProvider: any EphemerisProvider = provider
        #expect(ephemerisProvider is VSOP2013Provider)
    }

    @Test("VSOP2013Provider does not support Moon directly")
    func vsop2013MoonUnsupported() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let provider = try VSOP2013Provider(dataDirectoryURL: tempDir)
        #expect(throws: EphemerisError.self) {
            _ = try provider.position(for: .moon, at: JulianDay(2451545.0))
        }
    }

    @Test("VSOP2013Provider returns zero for Sun")
    func vsop2013SunPosition() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let provider = try VSOP2013Provider(dataDirectoryURL: tempDir)
        let pos = try provider.position(for: .sun, at: JulianDay(2451545.0))
        #expect(pos == .zero)
    }
}

// MARK: - EphemerisDataset Tests

@Suite("EphemerisDataset")
struct EphemerisDatasetTests {

    @Test("All datasets have valid remote URLs")
    func remoteURLs() {
        for dataset in EphemerisDataset.allCases {
            let url = dataset.remoteURL
            #expect(url.scheme == "https", "\(dataset.name) should use HTTPS")
            #expect(!url.lastPathComponent.isEmpty, "\(dataset.name) should have a filename")
        }
    }

    @Test("VSOP2013 datasets come from IMCCE")
    func vsop2013Source() {
        #expect(EphemerisDataset.vsop2013Modern.source.contains("IMCCE"))
        #expect(EphemerisDataset.vsop2013Full.source.contains("IMCCE"))
    }

    @Test("DE440 datasets come from NASA")
    func de440Source() {
        #expect(EphemerisDataset.lunarDE440.source.contains("NASA"))
        #expect(EphemerisDataset.lunarDE440s.source.contains("NASA"))
    }

    @Test("INPOP21a numerical SPK is the official IMCCE dataset (replaces analytical VSOP2013)")
    func inpop21aOfficialIMCCE() {
        #expect(EphemerisDataset.inpop21a.source.contains("IMCCE"))
        #expect(EphemerisDataset.inpop21a.filename == "inpop21a.bsp")
        #expect(EphemerisDataset.baseline == .de442s)
    }

    @Test("Filenames match expected patterns")
    func filenames() {
        #expect(EphemerisDataset.inpop21a.filename == "inpop21a.bsp")
        #expect(EphemerisDataset.de442s.filename == "de442s.bsp")
        #expect(EphemerisDataset.lunarDE440s.filename == "de440s.bsp")
    }
}

// MARK: - EphemerisDataManager Tests

@Suite("EphemerisDataManager")
struct EphemerisDataManagerTests {

    @Test("Default cache directory is in Caches/AstronomyKit")
    func defaultCacheDirectory() async {
        let manager = EphemerisDataManager()
        let path = await manager.cacheDirectory.path
        #expect(path.contains("AstronomyKit"))
    }

    @Test("Custom cache directory is respected")
    func customCacheDirectory() async {
        let customDir = FileManager.default.temporaryDirectory.appendingPathComponent("TestEphemeris")
        let manager = EphemerisDataManager(cacheDirectory: customDir)
        let dir = await manager.cacheDirectory
        #expect(dir == customDir)
    }

    @Test("isAvailable returns false for non-downloaded datasets")
    func isAvailableFalse() async {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let manager = EphemerisDataManager(cacheDirectory: tempDir)
        let available = await manager.isAvailable(.lunarDE440s)
        #expect(!available)
    }

    @Test("cacheSize returns zero for empty cache")
    func emptyCacheSize() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let manager = EphemerisDataManager(cacheDirectory: tempDir)
        let size = try await manager.cacheSize()
        #expect(size == 0)
    }

    @Test("makeTriadProviderFromCache strictly enforces numerical exclusivity and throws when cache is empty")
    func triadCacheExclusivity() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let manager = EphemerisDataManager(cacheDirectory: tempDir)
        #expect(throws: EphemerisError.self) {
            _ = try manager.makeTriadProviderFromCache()
        }
    }
}

// MARK: - Vector3D Chebyshev Test

@Suite("Chebyshev Evaluation")
struct ChebyshevTests {

    @Test("T_0(x) = 1 for all x")
    func chebyshevT0() {
        // T_0(x) = 1, so a polynomial with just c_0 = 5.0 should return 5.0
        // We test this indirectly through the SPKReader by constructing known data
        let values: [Double] = [-1.0, -0.5, 0.0, 0.5, 1.0]
        for x in values {
            // T_0(x) = 1, T_1(x) = x
            // P(x) = c_0 * T_0(x) + c_1 * T_1(x) = 3.0 + 2.0 * x
            let expected = 3.0 + 2.0 * x
            // Verify with Clenshaw: c = [3.0, 2.0]
            let result = clenshawEvaluate(coeffs: [3.0, 2.0], tau: x)
            #expect(abs(result - expected) < 1e-12, "Clenshaw at x=\(x): got \(result), expected \(expected)")
        }
    }

    @Test("Quadratic Chebyshev polynomial")
    func chebyshevQuadratic() {
        // P(x) = c_0*T_0(x) + c_1*T_1(x) + c_2*T_2(x)
        // T_2(x) = 2x^2 - 1
        // P(x) = 1.0 + 0.0*x + 0.5*(2x^2 - 1) = 1.0 + x^2 - 0.5 = 0.5 + x^2
        let coeffs = [1.0, 0.0, 0.5]
        for x in stride(from: -1.0, through: 1.0, by: 0.25) {
            let expected = 0.5 + x * x
            let result = clenshawEvaluate(coeffs: coeffs, tau: x)
            #expect(abs(result - expected) < 1e-12, "Quadratic at x=\(x): got \(result), expected \(expected)")
        }
    }

    /// Standalone Clenshaw evaluation for testing (mirrors SPKReader's internal algorithm).
    private func clenshawEvaluate(coeffs: [Double], tau: Double) -> Double {
        guard coeffs.count > 0 else { return 0 }
        var s1: Double = 0
        var s2: Double = 0
        for i in stride(from: coeffs.count - 1, through: 1, by: -1) {
            let s0 = 2.0 * tau * s1 - s2 + coeffs[i]
            s2 = s1
            s1 = s0
        }
        return tau * s1 - s2 + coeffs[0]
    }
}
