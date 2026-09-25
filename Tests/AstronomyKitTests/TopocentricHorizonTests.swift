//
//  TopocentricHorizonTests.swift
//  AstronomyKitTests
//
//  Tests for continuous vector topocentric horizon engine,
//  observer elevation horizon dip, Brent root-finding, and polar circle support.
//

import Testing
import Foundation
@testable import AstronomyKit

@Suite("Topocentric Horizon & Brent Root-Finding Tests")
struct TopocentricHorizonTests {

    @Test("Horizon depression (dip of the horizon) calculation and elevation scaling")
    func testHorizonDipCalculation() {
        // Sea level: zero dip
        let dip0 = TopocentricHorizonEngine.horizonDip(altitudeMeters: 0.0)
        #expect(dip0 == 0.0)

        // At 100 meters: dip ≈ 1.76' * 10 = 17.6' ≈ 0.2933°
        let dip100 = TopocentricHorizonEngine.horizonDip(altitudeMeters: 100.0)
        #expect(abs(dip100 - (17.6 / 60.0)) < 0.001)

        // At 2400 meters (Cerro Paranal Observatory): dip ≈ 1.76' * sqrt(2400) / 60 ≈ 1.437°
        let dipParanal = TopocentricHorizonEngine.horizonDip(altitudeMeters: 2400.0)
        #expect(abs(dipParanal - 1.437) < 0.01)

        // Below sea level (Dead Sea -430m): safe zero fallback without NaN
        let dipDeadSea = TopocentricHorizonEngine.horizonDip(altitudeMeters: -430.0)
        #expect(dipDeadSea == 0.0)

        // Non-finite guards
        let dipNaN = TopocentricHorizonEngine.horizonDip(altitudeMeters: Double.nan)
        #expect(dipNaN == 0.0)
        let dipInf = TopocentricHorizonEngine.horizonDip(altitudeMeters: Double.infinity)
        #expect(dipInf == 0.0)
    }

    @Test("Brent root-finding converges to sub-microsecond precision on trigonometric functions")
    func testBrentRootFindingAccuracy() {
        // f(x) = sin(x) - 0.5 on [0, pi/2]. Exact root is pi/6 ≈ 0.5235987755982988
        let root = TopocentricHorizonEngine.brentRoot(a: 0.0, b: 1.5, tol: 1e-12) { x in
            sin(x) - 0.5
        }

        #expect(root != nil)
        if let r = root {
            let exact = Double.pi / 6.0
            #expect(abs(r - exact) < 1.0e-11)
        }

        // Non-bracketing interval returns nil safely
        let nonBracket = TopocentricHorizonEngine.brentRoot(a: 1.0, b: 1.5, tol: 1e-7) { x in
            sin(x) - 0.5 // Both sin(1.0)-0.5 > 0 and sin(1.5)-0.5 > 0
        }
        #expect(nonBracket == nil)
    }

    @Test("Observer elevation shifts sunrise earlier and sunset later due to horizon dip")
    func testTopocentricSunRiseSetWithHorizonDip() {
        let date = JulianDay(year: 2026, month: 3, day: 20) // Equinox
        let sun = Sun(julianDay: date)

        // Location 1: Sea level (0m)
        let seaLevelLoc = GeographicCoordinates(positivelyWestwardLongitude: Degree(24.62), latitude: Degree(-24.62), altitude: 0)
        let timesSea = sun.topocentricRiseTransitSetTimes(for: seaLevelLoc)

        // Location 2: High elevation observatory (2400m)
        let mountainLoc = GeographicCoordinates(positivelyWestwardLongitude: Degree(24.62), latitude: Degree(-24.62), altitude: 2400)
        let timesMountain = sun.topocentricRiseTransitSetTimes(for: mountainLoc)

        #expect(timesSea.riseTime != nil && timesMountain.riseTime != nil)
        #expect(timesSea.setTime != nil && timesMountain.setTime != nil)

        if let rSea = timesSea.riseTime, let rMtn = timesMountain.riseTime {
            // Sunrise should be strictly EARLIER on the mountain
            #expect(rMtn < rSea)
            let diffMinutes = (rSea.value - rMtn.value) * 1440.0
            // Dip of ~1.4° shifts sunrise by ~5 to 8 minutes
            #expect(diffMinutes > 4.0 && diffMinutes < 10.0)
        }

        if let sSea = timesSea.setTime, let sMtn = timesMountain.setTime {
            // Sunset should be strictly LATER on the mountain
            #expect(sMtn > sSea)
            let diffMinutes = (sMtn.value - sSea.value) * 1440.0
            #expect(diffMinutes > 4.0 && diffMinutes < 10.0)
        }
    }

    @Test("Circumpolar Arctic regimes: Midnight Sun (June) and Polar Night (December) in Svalbard")
    func testPolarCircumpolarMidnightSunAndPolarNight() {
        // Longyearbyen, Svalbard (78.22° N)
        let svalbard = GeographicCoordinates(positivelyWestwardLongitude: Degree(-15.65), latitude: Degree(78.22), altitude: 50)

        // 1. Summer Solstice (Midnight Sun: Sun never sets)
        let summerJD = JulianDay(year: 2026, month: 6, day: 21)
        let summerSun = Sun(julianDay: summerJD)
        let summerTimes = summerSun.topocentricRiseTransitSetTimes(for: svalbard)

        #expect(summerTimes.riseTime == nil)
        #expect(summerTimes.setTime == nil)
        #expect(summerTimes.transitTime != nil) // Culmination still occurs
        #expect(summerTimes.transitError == .alwaysAboveAltitude)

        // 2. Winter Solstice (Polar Night: Sun never rises)
        let winterJD = JulianDay(year: 2026, month: 12, day: 21)
        let winterSun = Sun(julianDay: winterJD)
        let winterTimes = winterSun.topocentricRiseTransitSetTimes(for: svalbard)

        #expect(winterTimes.riseTime == nil)
        #expect(winterTimes.setTime == nil)
        #expect(winterTimes.transitError == .alwaysBelowAltitude)
    }

    @Test("High-precision topocentric rise, transit, set for Sirius at Cerro Paranal")
    func testHighPrecisionSiriusRiseTransitSet() {
        let jd = JulianDay(year: 2026, month: 1, day: 15)
        let coords = EquatorialCoordinates(rightAscension: Hour(.plus, 6, 45, 9.25), declination: Degree(.minus, 16, 42, 47.3))
        let sirius = AstronomicalObject(name: "Sirius", coordinates: coords, julianDay: jd)
        let paranal = GeographicCoordinates(positivelyWestwardLongitude: Degree(70.40), latitude: Degree(-24.62), altitude: 2400)

        let times = sirius.topocentricRiseTransitSetTimes(for: paranal)
        #expect(times.riseTime != nil)
        #expect(times.transitTime != nil)
        #expect(times.setTime != nil)
        #expect(times.transitError == nil)

        if let rise = times.riseTime, let transit = times.transitTime, let set = times.setTime {
            // On Jan 15 (0h to 24h UT), Sirius transits at ~03:48 UT, sets at ~10:18 UT, and rises at ~21:04 UT
            #expect(transit < set)
            #expect(set < rise)

            let altTransit = TopocentricHorizonEngine.altitudeForFixedEquatorial(
                alphaHours: coords.alpha.value,
                deltaDeg: coords.delta.value,
                jd: transit.value,
                geoCoords: paranal
            )
            #expect(altTransit > 80.0) // Culmination near zenith

            let targetAlt = TopocentricHorizonEngine.targetRiseSetAltitude(
                standardAltitudeDeg: -0.5667,
                altitudeMeters: paranal.altitude.value
            )
            let altRise = TopocentricHorizonEngine.altitudeForFixedEquatorial(
                alphaHours: coords.alpha.value,
                deltaDeg: coords.delta.value,
                jd: rise.value,
                geoCoords: paranal
            )
            let altSet = TopocentricHorizonEngine.altitudeForFixedEquatorial(
                alphaHours: coords.alpha.value,
                deltaDeg: coords.delta.value,
                jd: set.value,
                geoCoords: paranal
            )
            #expect(abs(altRise - targetAlt) < 0.005)
            #expect(abs(altSet - targetAlt) < 0.005)
        }
    }

    @Test("FixedEquatorialObserver matches altitudeForFixedEquatorial bit-exactly")
    func testFixedEquatorialObserverBitExact() {
        let paranal = GeographicCoordinates(
            positivelyWestwardLongitude: Degree(-70.4042),
            latitude: Degree(-24.6272),
            altitude: Meter(2635.43)
        )
        let alpha = 6.75257 // Sirius alpha hours
        let delta = -16.7161 // Sirius delta deg

        let observer = TopocentricHorizonEngine.FixedEquatorialObserver(
            alphaHours: alpha,
            deltaDeg: delta,
            geoCoords: paranal
        )

        for hourStep in 0...24 {
            let jd = 2460690.5 + Double(hourStep) / 24.0
            let altDirect = TopocentricHorizonEngine.altitudeForFixedEquatorial(
                alphaHours: alpha,
                deltaDeg: delta,
                jd: jd,
                geoCoords: paranal
            )
            let altObserver = observer.altitude(at: jd)
            #expect(abs(altDirect - altObserver) < 1e-14)
        }
    }

    @Test("GlobeEngine.rhoCoordinates matches scalar rhoSinThetaPrime and rhoCosThetaPrime")
    func testGlobeEngineRhoCoordinates() {
        let latitudes = [-90.0, -45.0, -24.6272, 0.0, 48.8566, 90.0]
        let altitudes = [0.0, 100.0, 2635.43, 8848.0]

        for lat in latitudes {
            for alt in altitudes {
                let (rhoSin, rhoCos) = GlobeEngine.rhoCoordinates(latitude: lat, height: alt)
                let directSin = GlobeEngine.rhoSinThetaPrime(latitude: lat, height: alt)
                let directCos = GlobeEngine.rhoCosThetaPrime(latitude: lat, height: alt)

                #expect(abs(rhoSin - directSin) < 1e-14)
                #expect(abs(rhoCos - directCos) < 1e-14)
            }
        }
    }
}
