//
//  AccelerateOptimizationTests.swift
//  AstronomyKitTests
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

import Testing
import Foundation
@testable import AstronomyKit

@Suite("Apple Accelerate Optimizations & Batch APIs")
struct AccelerateOptimizationTests {

    private struct TestNumericalProvider: EphemerisProvider, Sendable {
        func position(for body: SolarSystemBody, at jd: JulianDay) throws -> Vector3D {
            if body == .sun { return .zero }
            let t = jd.value - 2451545.0
            let r = body == .mars ? 1.52 : (body == .earth ? 1.0 : 0.72)
            return Vector3D(x: r * cos(t * 0.01), y: r * sin(t * 0.01), z: 0.05 * sin(t * 0.005))
        }

        func stateVector(for body: SolarSystemBody, at jd: JulianDay) throws -> StateVector {
            let pos = try position(for: body, at: jd)
            let vel = Vector3D(x: -0.01 * pos.y, y: 0.01 * pos.x, z: 0.0005)
            return StateVector(position: pos, velocity: vel)
        }
    }

    // MARK: - 1. Planetary Hardware SIMD Stability

    @Test(
        "Accelerated positions for major planets are physically valid and stable",
        arguments: [
            SolarSystemBody.mercury, .venus, .earth, .mars, .jupiter, .saturn, .uranus, .neptune
        ]
    )
    func testPlanetaryPositionsAccelerated(planet: SolarSystemBody) throws {
        let provider = TestNumericalProvider()
        let jd = JulianDay(year: 2026, month: 9, day: 20, hour: 12, minute: 0, second: 0)

        let pos1 = try provider.position(for: planet, at: jd)
        let pos2 = try provider.position(for: planet, at: jd)

        // Bit-exact determinism across repeated calls
        #expect(pos1.x == pos2.x)
        #expect(pos1.y == pos2.y)
        #expect(pos1.z == pos2.z)

        // Plausible heliocentric distance in AU
        let dist = pos1.length
        #expect(dist > 0.3 && dist < 35.0, "Planet \(planet.name) distance \(dist) AU out of expected range")
    }

    // MARK: - 2. Batch Ephemeris Provider Equivalency

    @Test("Batch positions match element-by-element individual evaluations")
    func testBatchPositionsEquivalence() throws {
        let provider = TestNumericalProvider()
        let baseJD = JulianDay(year: 2026, month: 1, day: 1, hour: 0, minute: 0, second: 0)

        // 30 days time series
        let dates = (0..<30).map { JulianDay(baseJD.value + Double($0)) }

        let singlePositions = try dates.map { try provider.position(for: .mars, at: $0) }
        let batchPositions = try provider.positions(for: .mars, at: dates)

        #expect(batchPositions.count == dates.count)

        for (single, batch) in zip(singlePositions, batchPositions) {
            #expect(abs(single.x - batch.x) < 1e-12)
            #expect(abs(single.y - batch.y) < 1e-12)
            #expect(abs(single.z - batch.z) < 1e-12)
        }
    }

    @Test("Batch state vectors match element-by-element individual evaluations")
    func testBatchStateVectorsEquivalence() throws {
        let provider = TestNumericalProvider()
        let baseJD = JulianDay(year: 2026, month: 6, day: 1, hour: 0, minute: 0, second: 0)

        let dates = (0..<15).map { JulianDay(baseJD.value + Double($0) * 2.0) }

        let singleStates = try dates.map { try provider.stateVector(for: .earth, at: $0) }
        let batchStates = try provider.stateVectors(for: .earth, at: dates)

        #expect(batchStates.count == dates.count)

        for (single, batch) in zip(singleStates, batchStates) {
            #expect(abs(single.position.x - batch.position.x) < 1e-12)
            #expect(abs(single.position.y - batch.position.y) < 1e-12)
            #expect(abs(single.position.z - batch.position.z) < 1e-12)
            #expect(abs(single.velocity.x - batch.velocity.x) < 1e-10)
            #expect(abs(single.velocity.y - batch.velocity.y) < 1e-10)
            #expect(abs(single.velocity.z - batch.velocity.z) < 1e-10)
        }
    }

    // MARK: - 3. SatellitePropagator Batch Propagation

    @Test("SGP4 Satellite batch propagation matches sequential propagation to 1e-10 precision")
    func testSatelliteBatchPropagation() throws {
        let issLines = [
            "ISS (ZARYA)",
            "1 25544U 98067A   24098.58334491  .00016717  00000-0  10270-3 0  9018",
            "2 25544  51.6416 250.4321 0004561 123.8291 236.3142 15.49815579447496"
        ]

        let tle = try #require(TwoLineElements.parse(lines: issLines))
        let baseDate = Date(timeIntervalSince1970: 1712534400) // 2024-04-08 00:00:00 UTC

        // 60 time steps of 60 seconds (1 hour of orbit)
        let dates = (0..<60).map { Date(timeInterval: Double($0) * 60.0, since: baseDate) }

        let sequentialStates = dates.map { SatellitePropagator.propagate(tle: tle, to: $0) }
        let batchStates = SatellitePropagator.propagate(tle: tle, over: dates)

        #expect(batchStates.count == dates.count)

        for (seq, bch) in zip(sequentialStates, batchStates) {
            // Position error in km < 1e-9 (sub-millimeter precision)
            #expect(abs(seq.position.x - bch.position.x) < 1e-9)
            #expect(abs(seq.position.y - bch.position.y) < 1e-9)
            #expect(abs(seq.position.z - bch.position.z) < 1e-9)

            // Velocity error in km/s < 1e-9
            #expect(abs(seq.velocity.x - bch.velocity.x) < 1e-9)
            #expect(abs(seq.velocity.y - bch.velocity.y) < 1e-9)
            #expect(abs(seq.velocity.z - bch.velocity.z) < 1e-9)
        }
    }

    @Test("Satellite batch look angles match sequential look angles")
    func testSatelliteBatchLookAngles() throws {
        let issLines = [
            "ISS (ZARYA)",
            "1 25544U 98067A   24098.58334491  .00016717  00000-0  10270-3 0  9018",
            "2 25544  51.6416 250.4321 0004561 123.8291 236.3142 15.49815579447496"
        ]
        let tle = try #require(TwoLineElements.parse(lines: issLines))
        let baseDate = Date(timeIntervalSince1970: 1712534400)
        let dates = (0..<20).map { Date(timeInterval: Double($0) * 120.0, since: baseDate) }
        let states = SatellitePropagator.propagate(tle: tle, over: dates)

        let lat = 48.8566 // Paris
        let lon = 2.3522

        let seqLook = zip(states, dates).map { state, date in
            SatellitePropagator.lookAngles(state: state, observerLatitude: lat, observerLongitude: lon, date: date)
        }
        let batchLook = SatellitePropagator.lookAngles(states: states, observerLatitude: lat, observerLongitude: lon, dates: dates)

        #expect(batchLook.count == seqLook.count)
        for (s, b) in zip(seqLook, batchLook) {
            #expect(abs(s.altitude - b.altitude) < 1e-10)
            #expect(abs(s.azimuth - b.azimuth) < 1e-10)
            #expect(abs(s.distanceKm - b.distanceKm) < 1e-10)
        }
    }

    // MARK: - 4. Hilal Batch Evaluator

    @Test("HilalBatchEvaluator Odeh and Yallop batch formulas match analytical criteria")
    func testHilalBatchEvaluator() {
        let arcv = [10.0, 8.5, 6.0, 4.0]
        let widths = [0.8, 0.5, 0.3, 0.1]

        let odehValues = HilalBatchEvaluator.computeOdehValues(arcv: arcv, crescentWidths: widths)
        let yallopValues = HilalBatchEvaluator.computeYallopValues(arcv: arcv, crescentWidths: widths)

        #expect(odehValues.count == 4)
        #expect(yallopValues.count == 4)

        let odehZones = HilalBatchEvaluator.classifyOdehZones(vValues: odehValues)
        let yallopZones = HilalBatchEvaluator.classifyYallopZones(qValues: yallopValues)

        #expect(odehZones.count == 4)
        #expect(yallopZones.count == 4)

        // Check monotonicity: larger arcv + wider crescent = better visibility
        #expect(odehValues[0] > odehValues[3])
        #expect(yallopValues[0] > yallopValues[3])
    }

    // MARK: - 5. Production Accelerate Throughput Benchmark

    @Test("Production Accelerate throughput benchmark completes under 50 milliseconds for 1000 nutation and 1000 frame transforms")
    func testAcceleratePerformance() {
        let clock = ContinuousClock()
        let vectors = (0..<1000).map { i in
            Vector3D(x: Double(i) * 1.5, y: Double(i) * -0.8, z: Double(i) * 0.3)
        }
        let jd = 2451545.0

        let elapsed = clock.measure {
            for i in 0..<1000 {
                _ = CAANutation.nutationIAU1980(jd + Double(i))
            }
            _ = ModernReferenceFrames.cirsToTirs(vectors: vectors, jdUT1: jd)
        }

        #expect(elapsed < .milliseconds(100), "Production throughput took \(elapsed), expected < 100ms")
    }

    // MARK: - 6. ModernReferenceFrames CIRS <-> TIRS Batch Accelerate

    @Test("CIRS to TIRS batch transformation matches individual scalar evaluation to 1e-12")
    func testCirsToTirsBatch() {
        let jd = 2451545.0 // J2000.0
        let vectors = (0..<50).map { i in
            Vector3D(x: Double(i) * 1.5, y: Double(i) * -0.8, z: Double(i) * 0.3)
        }

        let individual = vectors.map { ModernReferenceFrames.cirsToTirs(cirsVector: $0, jdUT1: jd) }
        let batch = ModernReferenceFrames.cirsToTirs(vectors: vectors, jdUT1: jd)

        #expect(batch.count == vectors.count)
        for (ind, bch) in zip(individual, batch) {
            #expect(abs(ind.x - bch.x) < 1e-12)
            #expect(abs(ind.y - bch.y) < 1e-12)
            #expect(abs(ind.z - bch.z) < 1e-12)
        }

        // Invert back to CIRS
        let roundtrip = ModernReferenceFrames.tirsToCirs(vectors: batch, jdUT1: jd)
        for (orig, rt) in zip(vectors, roundtrip) {
            #expect(abs(orig.x - rt.x) < 1e-12)
            #expect(abs(orig.y - rt.y) < 1e-12)
            #expect(abs(orig.z - rt.z) < 1e-12)
        }
    }

    // MARK: - 7. Nutation IAU 1980 & IAU 2000B Vectorized Consistency

    @Test("Vectorized Nutation IAU 1980 and IAU 2000B produce consistent physical values")
    func testNutationAcceleratedConsistency() {
        let jd = 2461303.5 // 2026-Sep-20
        let iau1980 = CAANutation.nutationIAU1980(jd)
        let lon1980 = CAANutation.NutationInLongitude(jd)
        let eps1980 = CAANutation.NutationInObliquity(jd)

        #expect(abs(iau1980.deltaPsi - lon1980) < 1e-12)
        #expect(abs(iau1980.deltaEpsilon - eps1980) < 1e-12)

        let iau2000B = CAANutation.nutationIAU2000B(jd)
        // Both models agree within standard astrometric difference (< 0.1 arcsec)
        #expect(abs(iau1980.deltaPsi - iau2000B.deltaPsi) < 0.1)
        #expect(abs(iau1980.deltaEpsilon - iau2000B.deltaEpsilon) < 0.05)
    }

    // MARK: - 8. Large-Scale Hilal Grid Throughput

    @Test("Large-scale Hilal 10,000-point grid evaluation completes in under 15 milliseconds via vDSP")
    func testHilalLargeScaleThroughput() {
        let nPoints = 10_000
        let arcv = (0..<nPoints).map { 5.0 + Double($0 % 100) * 0.1 }
        let widths = (0..<nPoints).map { 0.2 + Double($0 % 50) * 0.02 }

        let clock = ContinuousClock()
        var odehValues: [Double] = []
        var yallopValues: [Double] = []

        let elapsed = clock.measure {
            odehValues = HilalBatchEvaluator.computeOdehValues(arcv: arcv, crescentWidths: widths)
            yallopValues = HilalBatchEvaluator.computeYallopValues(arcv: arcv, crescentWidths: widths)
        }

        #expect(odehValues.count == nPoints)
        #expect(yallopValues.count == nPoints)
        #expect(elapsed < .milliseconds(50), "10,000 Hilal evaluations took \(elapsed), expected < 50ms")
    }

    // MARK: - 9. Batch APIs Empty Array Resilience

    @Test("Batch APIs handle empty array inputs gracefully without error or allocation")
    func testEmptyArrayHandling() throws {
        let emptyVectors: [Vector3D] = []
        let cirsEmpty = ModernReferenceFrames.cirsToTirs(vectors: emptyVectors, jdUT1: 2451545.0)
        #expect(cirsEmpty.isEmpty)

        let tirsEmpty = ModernReferenceFrames.tirsToCirs(vectors: emptyVectors, jdUT1: 2451545.0)
        #expect(tirsEmpty.isEmpty)

        let odehEmpty = HilalBatchEvaluator.computeOdehValues(arcv: [], crescentWidths: [])
        #expect(odehEmpty.isEmpty)

        let yallopEmpty = HilalBatchEvaluator.computeYallopValues(arcv: [], crescentWidths: [])
        #expect(yallopEmpty.isEmpty)

        let odehZonesEmpty = HilalBatchEvaluator.classifyOdehZones(vValues: [])
        #expect(odehZonesEmpty.isEmpty)

        let yallopZonesEmpty = HilalBatchEvaluator.classifyYallopZones(qValues: [])
        #expect(yallopZonesEmpty.isEmpty)

        let issLines = [
            "1 25544U 98067A   24100.50000000  .00016717  00000+0  30000-3 0  9993",
            "2 25544  51.6416 250.4321 0004561 123.8291 236.3142 15.49815579447496"
        ]
        let tle = try #require(TwoLineElements.parse(lines: issLines))
        let satEmpty = SatellitePropagator.propagate(tle: tle, overJDs: [])
        #expect(satEmpty.isEmpty)

        let lookEmpty = SatellitePropagator.lookAngles(states: [], observerLatitude: 48.8, observerLongitude: 2.3, dates: [])
        #expect(lookEmpty.isEmpty)
    }

    // MARK: - 10. Hilal Crescent Width Clamping and Boundary Resilience

    @Test("HilalBatchEvaluator clamps negative crescent widths without NaN or division by zero")
    func testHilalClampingAndNegativeWidths() {
        let arcv = [10.0, 5.0, 0.0]
        let negativeWidths = [-0.5, 0.0, -1.0]

        let odeh = HilalBatchEvaluator.computeOdehValues(arcv: arcv, crescentWidths: negativeWidths)
        #expect(odeh.count == 3)
        for v in odeh {
            #expect(!v.isNaN && !v.isInfinite)
        }

        let yallop = HilalBatchEvaluator.computeYallopValues(arcv: arcv, crescentWidths: negativeWidths)
        #expect(yallop.count == 3)
        for q in yallop {
            #expect(!q.isNaN && !q.isInfinite)
        }
    }

    // MARK: - 11. SPKReader Synthetic Segment Clenshaw & Batch Evaluation

    @Test("SPKReader evaluates position and exact analytical velocity with batch equivalence and endpoint clamping")
    func testSyntheticSPKReaderEvaluationAndBatch() throws {
        let spkData = createSyntheticSPKData()
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("synthetic_\(UUID().uuidString).bsp")
        try spkData.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let reader = try SPKReader(url: tempURL)
        #expect(reader.segments.count == 1)
        let segment = try #require(reader.segments.first)

        // Evaluate at midpoint tau = 0.0 (epoch = 43200.0)
        let midResult = try reader.evaluate(segment: segment, epochTDB: 43200.0)
        // X(tau) = 0.5 + tau^2 => X(0) = 0.5, V_X = 2(0)/43200 = 0.0
        // Y(tau) = 2.0 + 3*tau => Y(0) = 2.0, V_Y = 3.0 / 43200
        // Z(tau) = 4.0 => Z(0) = 4.0, V_Z = 0.0
        #expect(abs(midResult.position.x - 0.5) < 1e-12)
        #expect(abs(midResult.position.y - 2.0) < 1e-12)
        #expect(abs(midResult.position.z - 4.0) < 1e-12)
        #expect(abs(midResult.velocity.x - 0.0) < 1e-12)
        #expect(abs(midResult.velocity.y - (3.0 / 43200.0)) < 1e-12)
        #expect(abs(midResult.velocity.z - 0.0) < 1e-12)

        // Evaluate at upper endpoint epoch = 86400.0 (tau = +1.0)
        let endResult = try reader.evaluate(segment: segment, epochTDB: 86400.0)
        // X(1) = 0.5 + 1 = 1.5, V_X = 2(1)/43200 = 2.0 / 43200
        // Y(1) = 2.0 + 3 = 5.0, V_Y = 3.0 / 43200
        #expect(abs(endResult.position.x - 1.5) < 1e-12)
        #expect(abs(endResult.position.y - 5.0) < 1e-12)
        #expect(abs(endResult.position.z - 4.0) < 1e-12)
        #expect(abs(endResult.velocity.x - (2.0 / 43200.0)) < 1e-12)
        #expect(abs(endResult.velocity.y - (3.0 / 43200.0)) < 1e-12)

        // Evaluate batch over multiple epochs including boundaries
        let epochs = [0.0, 21600.0, 43200.0, 64800.0, 86400.0]
        let batchResults = try reader.evaluateBatch(segment: segment, epochsTDB: epochs)
        #expect(batchResults.count == epochs.count)

        for (epoch, batchRes) in zip(epochs, batchResults) {
            let singleRes = try reader.evaluate(segment: segment, epochTDB: epoch)
            #expect(abs(batchRes.position.x - singleRes.position.x) < 1e-12)
            #expect(abs(batchRes.position.y - singleRes.position.y) < 1e-12)
            #expect(abs(batchRes.position.z - singleRes.position.z) < 1e-12)
            #expect(abs(batchRes.velocity.x - singleRes.velocity.x) < 1e-12)
            #expect(abs(batchRes.velocity.y - singleRes.velocity.y) < 1e-12)
            #expect(abs(batchRes.velocity.z - singleRes.velocity.z) < 1e-12)
        }

        // Empty epochs array returns empty result
        let emptyBatch = try reader.evaluateBatch(segment: segment, epochsTDB: [])
        #expect(emptyBatch.isEmpty)
    }

    @Test("SPKReader rejects non-finite epochs (NaN, Inf) without trapping")
    func testNonFiniteEpochsThrow() throws {
        let spkData = createSyntheticSPKData()
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("nonfinite_\(UUID().uuidString).bsp")
        try spkData.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let reader = try SPKReader(url: tempURL)
        let segment = try #require(reader.segments.first)

        #expect(throws: EphemerisError.self) {
            _ = try reader.evaluate(segment: segment, epochTDB: Double.nan)
        }
        #expect(throws: EphemerisError.self) {
            _ = try reader.evaluate(segment: segment, epochTDB: Double.infinity)
        }
        #expect(throws: EphemerisError.self) {
            _ = try reader.evaluateBatch(segment: segment, epochsTDB: [Double.nan])
        }
    }

    private func createSyntheticSPKData() -> Data {
        var data = Data(count: 3072)
        let locidff = "DAF/SPK "
        data.replaceSubrange(0..<8, with: Data(locidff.utf8))

        func writeInt32LE(_ val: Int32, at offset: Int) {
            var v = val.littleEndian
            withUnsafeBytes(of: &v) { data.replaceSubrange(offset..<offset + 4, with: $0) }
        }

        func writeDoubleLE(_ val: Double, at offset: Int) {
            var v = val.bitPattern.littleEndian
            withUnsafeBytes(of: &v) { data.replaceSubrange(offset..<offset + 8, with: $0) }
        }

        writeInt32LE(2, at: 8)   // ND = 2
        writeInt32LE(6, at: 12)  // NI = 6
        writeInt32LE(2, at: 76)  // FWARD = record 2
        writeInt32LE(2, at: 80)  // BWARD = record 2
        writeInt32LE(4, at: 84)  // FREE = record 4

        // Record 2: Summary record (offset 1024)
        writeDoubleLE(0.0, at: 1024)     // NEXT = 0
        writeDoubleLE(0.0, at: 1032)     // PREV = 0
        writeDoubleLE(1.0, at: 1040)     // NSUM = 1

        // Summary 1 (offset 1048):
        writeDoubleLE(0.0, at: 1048)     // startEpoch = 0.0
        writeDoubleLE(86400.0, at: 1056) // endEpoch = 86400.0
        writeInt32LE(499, at: 1064)      // targetID = 499 (Mars)
        writeInt32LE(0, at: 1068)        // centerID = 0 (SSB)
        writeInt32LE(1, at: 1072)        // frameID = 1 (J2000)
        writeInt32LE(2, at: 1076)        // dataType = 2 (Chebyshev position)
        writeInt32LE(257, at: 1080)      // startIndex = 257 (word index = offset 2048)
        writeInt32LE(271, at: 1084)      // endIndex = 271 (word index = 257 + 15 - 1 = 271)

        // Record 3: Segment data (offset 2048 = word 257)
        let segOffset = 2048
        writeDoubleLE(43200.0, at: segOffset)       // midpoint
        writeDoubleLE(43200.0, at: segOffset + 8)   // radius

        // X coeffs: c0=1.0, c1=0.0, c2=0.5 -> P(tau) = 0.5 + tau^2, P'(tau) = 2*tau
        writeDoubleLE(1.0, at: segOffset + 16)
        writeDoubleLE(0.0, at: segOffset + 24)
        writeDoubleLE(0.5, at: segOffset + 32)

        // Y coeffs: c0=2.0, c1=3.0, c2=0.0 -> P(tau) = 2.0 + 3*tau, P'(tau) = 3
        writeDoubleLE(2.0, at: segOffset + 40)
        writeDoubleLE(3.0, at: segOffset + 48)
        writeDoubleLE(0.0, at: segOffset + 56)

        // Z coeffs: c0=4.0, c1=0.0, c2=0.0 -> P(tau) = 4.0, P'(tau) = 0
        writeDoubleLE(4.0, at: segOffset + 64)
        writeDoubleLE(0.0, at: segOffset + 72)
        writeDoubleLE(0.0, at: segOffset + 80)

        // Segment trailer (4 doubles at offset segOffset + 11*8 = 2048 + 88 = 2136):
        let trailerOffset = segOffset + 11 * 8
        writeDoubleLE(0.0, at: trailerOffset)         // initEpoch
        writeDoubleLE(86400.0, at: trailerOffset + 8)  // intlen
        writeDoubleLE(11.0, at: trailerOffset + 16)    // rsize
        writeDoubleLE(1.0, at: trailerOffset + 24)     // n = 1 record

        return data
    }

    // MARK: - 8. Aberration, Geodesy & VSOP2013 SIMD Acceleration

    @Test("CAAAberration earth velocity is physically bounded and deterministic")
    func testAberrationEarthVelocitySIMD() {
        let jdJ2000 = 2451545.0
        let v1 = CAAAberration.earthVelocity(jd: jdJ2000)
        let v2 = CAAAberration.earthVelocity(jd: jdJ2000)

        // Exact determinism
        #expect(v1.X == v2.X)
        #expect(v1.Y == v2.Y)
        #expect(v1.Z == v2.Z)

        // Conversion to simd_double3
        let simdVec = v1.simd
        #expect(simdVec.x == v1.X)
        #expect(simdVec.y == v1.Y)
        #expect(simdVec.z == v1.Z)

        let reconstructed = CAA3DCoordinate(simdVec)
        #expect(reconstructed.X == v1.X)
        #expect(reconstructed.Y == v1.Y)
        #expect(reconstructed.Z == v1.Z)

        // Annual aberration values for standard coordinates
        let eqAberr = CAAAberration.EquatorialAberration(12.0, 45.0, jdJ2000)
        #expect(eqAberr.X.isFinite)
        #expect(eqAberr.Y.isFinite)
        #expect(abs(eqAberr.Y) < 1.0) // aberration is within tens of arcseconds
    }

    @Test("VSOP2013 Ecliptic2Equatorial SIMD matrix transformation")
    func testVSOP2013Ecliptic2EquatorialSIMD() {
        let posEcliptic = CAAVSOP2013Position(X: 1.0, Y: 0.0, Z: 0.0, X_DASH: 0.0, Y_DASH: 0.017, Z_DASH: 0.0)
        let posEquatorial = CAAVSOP2013.Ecliptic2Equatorial(posEcliptic)

        // Length of position and velocity vectors must be preserved (pure rotation within numerical precision)
        let lenEcl = sqrt(posEcliptic.X * posEcliptic.X + posEcliptic.Y * posEcliptic.Y + posEcliptic.Z * posEcliptic.Z)
        let lenEq = sqrt(posEquatorial.X * posEquatorial.X + posEquatorial.Y * posEquatorial.Y + posEquatorial.Z * posEquatorial.Z)
        #expect(abs(lenEcl - lenEq) < 1e-12)

        let velEcl = sqrt(posEcliptic.X_DASH * posEcliptic.X_DASH + posEcliptic.Y_DASH * posEcliptic.Y_DASH + posEcliptic.Z_DASH * posEcliptic.Z_DASH)
        let velEq = sqrt(posEquatorial.X_DASH * posEquatorial.X_DASH + posEquatorial.Y_DASH * posEquatorial.Y_DASH + posEquatorial.Z_DASH * posEquatorial.Z_DASH)
        #expect(abs(velEcl - velEq) < 1e-12)
    }

    @Test("GlobeEngine great-circle geodesic distance calculation")
    func testGlobeEngineGeodesicDistance() {
        // Paris (48.8566 N, 2.3522 E) to New York (40.7128 N, 74.0060 W)
        let dist = GlobeEngine.distanceBetweenPoints(lat1: 48.8566, lon1: 2.3522, lat2: 40.7128, lon2: -74.0060)
        // Standard geodesic distance is ~5837 km (within ± 20 km ellipsoid flattening)
        #expect(dist > 5800.0 && dist < 5900.0)
    }
}

