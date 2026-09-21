//
//  ModernFeaturesTests.swift
//  AstronomyKitTests
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

import Testing
import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif
@testable import AstronomyKit

@Suite("State-of-the-Art Features & Ergonomics")
struct ModernFeaturesTests {

    // MARK: - SolarSystemBody Tests

    @Test("SolarSystemBody enumeration coverage and symbols")
    func solarSystemBodies() {
        #expect(SolarSystemBody.allCases.count == 11)
        #expect(SolarSystemBody.mars.symbol == "♂")
        #expect(SolarSystemBody.sun.symbol == "☉")
        #expect(SolarSystemBody.moon.symbol == "☽")
        #expect(SolarSystemBody.jupiter.symbol == "♃")
        #expect(SolarSystemBody.saturn.symbol == "♄")
    }

    @Test("SolarSystemBody ephemeris snapshot generation")
    func solarSystemEphemeris() {
        let jd = JulianDay(year: 2024, month: 4, day: 8, hour: 18, minute: 17)
        let marsSnapshot = SolarSystemBody.mars.ephemeris(at: jd)
        #expect(marsSnapshot.body == .mars)
        #expect(marsSnapshot.radiusVector.value > 1.3)
        #expect(marsSnapshot.equatorialCoordinates != nil)
        #expect(marsSnapshot.apparentMagnitude != nil)

        let sunSnapshot = SolarSystemBody.sun.ephemeris(at: jd)
        #expect(sunSnapshot.body == .sun)
        #expect(sunSnapshot.apparentMagnitude == -26.74)
        #expect(sunSnapshot.radiusVector.value > 0.98 && sunSnapshot.radiusVector.value < 1.02)

        let moonSnapshot = SolarSystemBody.moon.ephemeris(at: jd)
        #expect(moonSnapshot.body == .moon)
        #expect(moonSnapshot.illuminatedFraction != nil)
    }

    // MARK: - Moon Phases Tests

    @Test("Eight-phase LunarPhase division classification", arguments: [
        (Degree(0.0), LunarPhase.newMoon),
        (Degree(45.0), LunarPhase.waxingCrescent),
        (Degree(90.0), LunarPhase.firstQuarter),
        (Degree(135.0), LunarPhase.waxingGibbous),
        (Degree(180.0), LunarPhase.fullMoon),
        (Degree(225.0), LunarPhase.waningGibbous),
        (Degree(270.0), LunarPhase.lastQuarter),
        (Degree(315.0), LunarPhase.waningCrescent)
    ])
    func lunarPhaseClassification(elongation: Degree, expectedPhase: LunarPhase) {
        let phase = LunarPhase(elongation: elongation)
        #expect(phase == expectedPhase)
    }

    @Test("Next primary phase prediction using CAAMoonPhases")
    func nextMoonQuarter() {
        // Start near J2000 epoch
        let startJD = JulianDay(2451545.0) // 2000-01-01 12:00
        let nextFull = Moon.nextPhase(.fullMoon, after: startJD)
        #expect(nextFull > startJD)

        // The first Full Moon of 2000 occurred on 2000 January 21 ~ 04:40 UTC (JD ~ 2451564.7)
        #expect(abs(nextFull.value - 2451564.7) < 0.5)
    }

    @Test("Moon phases sequence in date range")
    func moonPhasesSequence() {
        let startJD = JulianDay(year: 2024, month: 1, day: 1)
        let endJD = JulianDay(year: 2024, month: 2, day: 1)
        let events = Moon.phases(from: startJD, to: endJD)

        #expect(!events.isEmpty)
        // Verify chronological order
        for i in 0..<(events.count - 1) {
            #expect(events[i].julianDay < events[i+1].julianDay)
        }
    }

    // MARK: - Angular Separation Tests

    @Test("Universal angular separation between celestial bodies during eclipse")
    func celestialBodyAngularSeparation() {
        // During a solar eclipse, Moon and Sun angular separation is near 0°
        // Eclipse reference epoch: 1993 May 21
        let jd = JulianDay(year: 1993, month: 5, day: 21, hour: 14, minute: 19)
        let sun = Sun(julianDay: jd)
        let moon = Moon(julianDay: jd)

        let separation = sun.angularSeparation(from: moon)
        // Geocentric separation during eclipse is small (< 1.5 degrees)
        #expect(separation.value < 1.5)
    }

    // MARK: - Meteor Showers Tests

    @Test("Meteor shower catalog and peak calculations")
    func meteorShowers() {
        let perseids = MeteorShower.perseids
        #expect(perseids.name == "Perseids")
        #expect(perseids.zhr == 100)
        #expect(perseids.parentBody == "109P/Swift-Tuttle")

        let peak2024 = perseids.peakJulianDay(year: 2024)
        #expect(peak2024.date.year == 2024)
        #expect(peak2024.date.month == 8)
        #expect(peak2024.date.day == 12)

        let illum = perseids.moonIlluminationAtPeak(year: 2024)
        #expect(illum >= 0.0 && illum <= 1.0)
        let rating = perseids.observationRating(year: 2024)
        #expect(!rating.description.isEmpty)

        #expect(MeteorShower.majorShowers.count == 8)
    }

    // MARK: - SwiftUI Interop Tests

    #if canImport(SwiftUI)
    @Test("SwiftUI Angle interop")
    func swiftUIAngleInterop() {
        let deg = Degree(180.0)
        let swiftAngle = deg.asSwiftUIAngle
        #expect(swiftAngle.degrees == 180.0)

        let roundTrip = Degree(swiftAngle)
        #expect(roundTrip.value == 180.0)

        let rad = Radian(Double.pi)
        let swiftRadAngle = rad.asSwiftUIAngle
        #expect(abs(swiftRadAngle.radians - Double.pi) < 1e-9)
    }
    #endif

    // MARK: - FormatStyle Declarative Tests

    @Test("Declarative FormatStyle on Degree and Hour")
    func formatStyleDeclarative() {
        let degree = Degree(45.5)
        let formattedDeg = degree.formatted(.sexagesimal(includeSign: true, fractionDigits: 1))
        #expect(formattedDeg.contains("45°"))
        #expect(formattedDeg.contains("30'"))

        let hour = Hour(12.5)
        let formattedHour = hour.formatted(.rightAscension(fractionDigits: 1))
        #expect(formattedHour.contains("12h"))
        #expect(formattedHour.contains("30m"))
    }
}
