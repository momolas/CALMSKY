//
//  ModernAstrometricStandardsTests.swift
//  AstronomyKitTests
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

import Testing
import Foundation
@testable import AstronomyKit

@Suite("Modern Astrometric Standards Tests (IAU 2006, IERS 2010, BIPM Ciddor)")
struct ModernAstrometricStandardsTests {

    // MARK: - Relativistic Time Scales (IAU 2006 / Fairhead & Bretagnon 1990)

    @Test("Relativistic TDB minus TT amplitude stays bounded within +/- 2 milliseconds")
    func testTdbMinusTTAmpitude() {
        // Sample throughout an entire year at 10-day intervals
        let j2000 = 2451545.0
        var maxDiff: Double = 0.0

        for day in stride(from: 0.0, through: 365.25, by: 10.0) {
            let jdTT = j2000 + day
            let diffSec = AstronomicalTimeScale.tdbMinusTT(jdTT: jdTT)
            #expect(diffSec.isFinite)
            maxDiff = max(maxDiff, abs(diffSec))
        }

        // Peak geocentric TDB - TT is ~1.66 milliseconds (0.00166s)
        #expect(maxDiff > 0.0015)
        #expect(maxDiff < 0.0018)
    }

    @Test("Relativistic TT to TDB and TDB to TT round-trip consistency")
    func testTTTDBRoundTrip() {
        let testEpochs: [Double] = [
            2451545.0, // J2000.0
            2460000.5, // 2023
            2461127.0, // 2026
            2440000.0  // 1968
        ]

        for epoch in testEpochs {
            let tdb = AstronomicalTimeScale.ttToTDB(jdTT: epoch)
            let ttRestored = AstronomicalTimeScale.tdbToTT(jdTDB: tdb)
            // Round trip should be accurate to within microsecond (< 1e-11 days)
            #expect(abs(ttRestored - epoch) < 1e-10)
        }
    }

    @Test("TDB minus TT rejects non-finite inputs gracefully")
    func testTDBNonFiniteGraceful() {
        #expect(AstronomicalTimeScale.tdbMinusTT(jdTT: .nan) == 0.0)
        #expect(AstronomicalTimeScale.tdbMinusTT(jdTT: .infinity) == 0.0)
    }

    // MARK: - Secular Delta T (Stephenson, Morrison & Hohenkerk 2016)

    @Test("Delta T Stephenson 2016 matches historical and modern regimes")
    func testDeltaTStephenson2016() {
        // Modern 2000.0 epoch: table measured value ~63.83s
        let jd2000 = 2451545.0
        let dt2000 = AstronomicalTimeScale.deltaTStephenson2016(for: jd2000)
        #expect(abs(dt2000 - 63.83) < 0.5)

        // Modern 2026 epoch: IERS Bulletin A ~69.2s - 69.8s
        let jd2026 = 2461041.5
        let dt2026 = AstronomicalTimeScale.deltaTStephenson2016(for: jd2026)
        #expect(dt2026 > 68.5 && dt2026 < 71.0)

        // Historical 1820 epoch: minimum of tidal parabola, Delta T ~ 12s
        let jd1820 = 2385800.5
        let dt1820 = AstronomicalTimeScale.deltaTStephenson2016(for: jd1820)
        #expect(dt1820 > 5.0 && dt1820 < 15.0)

        // Ancient Babylon era (year -500): Delta T ~ 17000s (~4.7 hours)
        let jdMinus500 = 1538555.5
        let dtAncient = AstronomicalTimeScale.deltaTStephenson2016(for: jdMinus500)
        #expect(dtAncient > 14000.0 && dtAncient < 20000.0)
    }

    // MARK: - BIPM Ciddor (1996/2002) Atmospheric Refraction

    @Test("Ciddor refractivity at standard conditions matches physical BIPM benchmark")
    func testCiddorRefractivityStandard() {
        // Standard dry air at 15°C, 1013.25 hPa, 450 ppm CO2, 0% RH, 550nm
        let paramsDry = CiddorParameters(wavelengthMicrometers: 0.55, co2Ppm: 450.0, relativeHumidity: 0.0)
        let nMinus1 = AtmosphericRefractionEngine.ciddorRefractivity(
            pressureHPa: 1013.25,
            temperatureC: 15.0,
            params: paramsDry
        )

        // Standard refractivity (n - 1) of dry air is ~ 2.72e-4 to 2.78e-4
        #expect(nMinus1 > 2.70e-4 && nMinus1 < 2.80e-4)

        // Moist air (50% RH) has slightly lower refractivity due to water vapor density
        let paramsMoist = CiddorParameters(wavelengthMicrometers: 0.55, co2Ppm: 450.0, relativeHumidity: 50.0)
        let nMinus1Moist = AtmosphericRefractionEngine.ciddorRefractivity(
            pressureHPa: 1013.25,
            temperatureC: 15.0,
            params: paramsMoist
        )
        #expect(nMinus1Moist < nMinus1)
    }

    @Test("Ciddor chromatic dispersion exhibits higher refraction for blue/O-III than red/H-alpha")
    func testCiddorChromaticDispersion() {
        // O-III (500.7 nm) has shorter wavelength than H-alpha (656.28 nm), so refractive index must be higher
        let nOIII = AtmosphericRefractionEngine.ciddorRefractivity(params: .oIII)
        let nHAlpha = AtmosphericRefractionEngine.ciddorRefractivity(params: .hAlpha)
        #expect(nOIII > nHAlpha)

        // At 45° altitude, refraction difference (chromatic dispersion) is noticeable in astrophotography
        let rOIII = AtmosphericRefractionEngine.ciddorRefraction(apparentAltitude: 45.0, params: .oIII)
        let rHAlpha = AtmosphericRefractionEngine.ciddorRefraction(apparentAltitude: 45.0, params: .hAlpha)
        #expect(rOIII > rHAlpha)
    }

    @Test("Ciddor refraction angle behavior across horizons")
    func testCiddorRefractionHorizon() {
        // 1. Zenith: refraction is zero
        let rZenith = AtmosphericRefractionEngine.ciddorRefraction(apparentAltitude: 90.0)
        #expect(rZenith == 0.0)

        // 2. 45° altitude: ~ 1 arcminute (~ 0.016°)
        let r45 = AtmosphericRefractionEngine.ciddorRefraction(apparentAltitude: 45.0)
        #expect(r45 > 0.014 && r45 < 0.018)

        // 3. Apparent horizon 0°: Saemundsson/Ciddor yields ~ 29 arcminutes (~ 0.48°)
        let rHorizon = AtmosphericRefractionEngine.ciddorRefraction(apparentAltitude: 0.0)
        #expect(rHorizon > 0.45 && rHorizon < 0.52)

        // 4. Horizon inversion: true geometric altitude 0° appears ~ 0.43° above horizon
        let appAtZeroTrue = AtmosphericRefractionEngine.apparentAltitudeFromTrue(trueAltitude: 0.0)
        #expect(appAtZeroTrue > 0.40 && appAtZeroTrue < 0.46)

        // A body whose airless true altitude is -rHorizon appears on the horizon (~ 0.0°)
        let appAtSetting = AtmosphericRefractionEngine.apparentAltitudeFromTrue(trueAltitude: -rHorizon)
        #expect(abs(appAtSetting) < 0.02)
    }

    @Test("High-level refractionCiddor API round-trip between apparent and true altitude")
    func testRefractionCiddorRoundTrip() {
        let apparentAltitudes: [Double] = [5.0, 15.0, 30.0, 60.0, 80.0]

        for alt in apparentAltitudes {
            let appDeg = Degree(alt)
            let rArcmin = refractionCiddor(fromApparentAltitude: appDeg)
            let trueDeg = appDeg - rArcmin.inDegrees

            // Now reconstruct apparent from true
            let rReconstructed = refractionCiddor(fromTrueAltitude: trueDeg)
            #expect(abs(rReconstructed.value - rArcmin.value) < 0.005)
        }
    }
}
