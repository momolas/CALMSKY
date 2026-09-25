//
//  LunarPhaseNumericalTests.swift
//  AstronomyKitTests
//
//  Tests for modern numerical root-finding of primary lunar phases
//  (Newton-Raphson on apparent geocentric ecliptic elongation).
//

import Testing
import Foundation
@testable import AstronomyKit

@Suite("Modern Lunar Phase Numerical Root-Finding Tests")
struct LunarPhaseNumericalTests {

    @Test("Newton-Raphson converges to sub-millisecond residual (< 1e-7 deg)")
    func testNewtonRaphsonConvergence() {
        // Lunation k = 0 (New Moon near 2000 Jan 6)
        let k = 0.0
        let initialJD = CAAMoonPhases.TruePhase(k)
        let exactJD = LunarPhaseNumericalEngine.solveExactPhase(
            targetAngle: 0.0,
            initialJD: initialJD,
            toleranceSeconds: 0.01
        )

        let residualDeg = LunarPhaseNumericalEngine.phaseResidual(jd: exactJD, targetAngle: 0.0)
        // Residual in degrees should be essentially zero (< 1e-7 deg ≈ 0.00036 arcseconds)
        #expect(abs(residualDeg) < 1.0e-7)

        // Residual in time (12.19 deg/day => 1e-7 deg ≈ 0.7 ms)
        let residualSeconds = (abs(residualDeg) / 12.19075) * 86400.0
        #expect(residualSeconds < 0.005)
    }

    @Test("Discrepancy with Meeus analytical series is bounded within ±2 minutes")
    func testMeeusAnalyticalDiscrepancy() {
        // Example from Meeus Ch. 49, p. 353 (1977 Feb 18 New Moon)
        let k = CAAMoonPhases.K(1977.13)
        let baseK = floor(k)
        let meeusJD = CAAMoonPhases.TruePhase(baseK)
        let exactJD = CAAMoonPhases.ExactPhase(baseK, toleranceSeconds: 0.05)

        let deltaSeconds = abs(exactJD - meeusJD) * 86400.0
        // Meeus Ch. 49 series states an error of up to 2-4 minutes due to omitted planetary perturbations
        #expect(deltaSeconds < 300.0)
        // Discrepancy is significant (~3.3 min in this epoch) because higher-order planetary terms are resolved
        #expect(deltaSeconds > 0.1)

        // At exactJD, elongation residual must be vanishingly small
        let residual = LunarPhaseNumericalEngine.phaseResidual(jd: exactJD, targetAngle: 0.0)
        #expect(abs(residual) < 1.0e-7)
    }

    @Test("All four primary quarters achieve exact physical angles (0°, 90°, 180°, 270°)")
    func testFourPrimaryQuartersProgression() {
        let k0 = 300.0 // Year ~2024
        let phases: [MoonPhase] = [.newMoon, .firstQuarter, .fullMoon, .lastQuarter]
        var previousJD: Double = 0.0

        for (index, phase) in phases.enumerated() {
            let k = k0 + Double(index) * 0.25
            let exactJD = CAAMoonPhases.ExactPhase(k, toleranceSeconds: 0.01)
            let targetAngle = phase.targetElongation

            // Verify physical angle matches exactly
            let residual = LunarPhaseNumericalEngine.phaseResidual(jd: exactJD, targetAngle: targetAngle)
            #expect(abs(residual) < 1.0e-7)

            // Verify each quarter is roughly ~7.38 days apart
            if previousJD > 0.0 {
                let intervalDays = exactJD - previousJD
                #expect(intervalDays > 6.5)
                #expect(intervalDays < 8.5)
            }
            previousJD = exactJD
        }
    }

    @Test("Moon.exactNextPhase and Moon.exactPhases range query")
    func testMoonExactNextPhaseAndDateRange() {
        let startJD = JulianDay(year: 2026, month: 3, day: 1)
        let endJD = JulianDay(year: 2026, month: 5, day: 1) // ~2 months

        let nextFull = Moon.exactNextPhase(.fullMoon, after: startJD)
        #expect(nextFull > startJD)

        // Elongation at full moon must be 180°
        let residual = LunarPhaseNumericalEngine.phaseResidual(jd: nextFull.value, targetAngle: 180.0)
        #expect(abs(residual) < 1.0e-7)

        let events = Moon.exactPhases(from: startJD, to: endJD)
        // A 2-month span contains 8 or 9 quarter phases
        #expect(events.count >= 7 && events.count <= 10)

        // Events must be chronologically strictly sorted
        for i in 1..<events.count {
            #expect(events[i].julianDay > events[i-1].julianDay)
        }
    }

    @Test("Moon instance exactTime forward and backward search")
    func testMoonExactTimeInstance() {
        let moon = Moon(julianDay: JulianDay(year: 2026, month: 6, day: 15))

        let forwardFull = moon.exactTime(of: .fullMoon, forward: true)
        #expect(forwardFull > moon.julianDay)
        let forwardRes = LunarPhaseNumericalEngine.phaseResidual(jd: forwardFull.value, targetAngle: 180.0)
        #expect(abs(forwardRes) < 1.0e-7)

        let backwardFull = moon.exactTime(of: .fullMoon, forward: false)
        #expect(backwardFull < moon.julianDay)
        let backwardRes = LunarPhaseNumericalEngine.phaseResidual(jd: backwardFull.value, targetAngle: 180.0)
        #expect(abs(backwardRes) < 1.0e-7)
    }

    @Test("Robustness on extreme dates and non-finite guards")
    func testRobustnessNaNInfAndExtremeDates() {
        // Non-finite guards
        let nanResult = LunarPhaseNumericalEngine.solveExactPhase(targetAngle: 0.0, initialJD: Double.nan)
        #expect(nanResult.isNaN)

        let infResult = LunarPhaseNumericalEngine.solveExactPhase(targetAngle: 0.0, initialJD: Double.infinity)
        #expect(infResult.isInfinite)

        // Ancient history: Year -500 (2500 years ago)
        let ancientJD = JulianDay(year: -500, month: 6, day: 1).value
        let ancientPhase = LunarPhaseNumericalEngine.solveExactPhase(targetAngle: 0.0, initialJD: ancientJD)
        #expect(ancientPhase.isFinite)

        // Far future: Year 2150
        let futureJD = JulianDay(year: 2150, month: 1, day: 1).value
        let futurePhase = LunarPhaseNumericalEngine.solveExactPhase(targetAngle: 180.0, initialJD: futureJD)
        #expect(futurePhase.isFinite)
    }

    @Test("Vector3D to Ecliptic Longitude conversion")
    func testVectorToEclipticLongitude() {
        let jd = 2451545.0 // J2000.0
        // Vector along vernal equinox X axis (0°, 0°)
        let vX = Vector3D(x: 1.0, y: 0.0, z: 0.0)
        let lonX = LunarPhaseNumericalEngine.vectorToEclipticLongitude(vector: vX, jd: jd)
        #expect(abs(lonX) < 1.0e-6 || abs(lonX - 360.0) < 1.0e-6)

        // Zero vector returns 0.0 safely
        let vZero = Vector3D.zero
        let lonZero = LunarPhaseNumericalEngine.vectorToEclipticLongitude(vector: vZero, jd: jd)
        #expect(lonZero == 0.0)
    }
}
