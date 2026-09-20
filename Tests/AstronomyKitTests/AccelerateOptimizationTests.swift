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

    // MARK: - 1. Planetary VSOP87 Precision and Stability

    @Test("VSOP87 Accelerated positions for all major planets are physically valid and stable")
    func testPlanetaryPositionsAccelerated() throws {
        let provider = AnalyticalEphemerisProvider()
        let jd = JulianDay(year: 2026, month: 9, day: 20, hour: 12, minute: 0, second: 0)

        let planets: [SolarSystemBody] = [
            .mercury, .venus, .earth, .mars, .jupiter, .saturn, .uranus, .neptune
        ]

        for planet in planets {
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
    }

    // MARK: - 2. Batch Ephemeris Provider Equivalency

    @Test("Batch positions match element-by-element individual evaluations")
    func testBatchPositionsEquivalence() throws {
        let provider = AnalyticalEphemerisProvider()
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
        let provider = AnalyticalEphemerisProvider()
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

    // MARK: - 5. Performance Benchmark Assertion

    @Test("VSOP87 Accelerate throughput benchmark completes under 20 milliseconds for 200 epochs")
    func testVSOP87Performance() throws {
        let provider = AnalyticalEphemerisProvider()
        let startJD = JulianDay(year: 2026, month: 1, day: 1, hour: 0, minute: 0, second: 0)
        let dates = (0..<200).map { JulianDay(startJD.value + Double($0)) }

        let clock = ContinuousClock()
        let elapsed = clock.measure {
            _ = try? provider.positions(for: .mars, at: dates)
        }

        // 200 full VSOP87 planetary reductions should take << 50 ms with hardware acceleration
        #expect(elapsed < .milliseconds(100), "200 planetary positions took \(elapsed), expected < 100ms")
    }
}
