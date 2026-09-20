//
//  ExtendedFeatureTests.swift
//  SwiftAA
//
//  Created for SwiftAA Extended Features Testing.
//  MIT Licence. See LICENCE file.
//

import Testing
import Foundation
@testable import AstronomyKit

@Suite("Extended Features & Modern Ergonomics")
struct ExtendedFeatureTests {
    
    // MARK: - Eclipses Tests
    @Test("Solar Eclipse calculation (Meeus Example 54.a: 1993 May 21)")
    func solarEclipsePrediction() {
        // k = -82.0 corresponds to New Moon of 1993 May 21
        let eclipse = Eclipses.calculateSolar(k: -82.0)
        #expect(eclipse.isPartial)
        #expect(!eclipse.isTotal)
        #expect(abs(eclipse.greatestMagnitude - 0.735) < 0.05)
    }

    @Test("Lunar Eclipse calculation (Meeus Example 54.b: 1973 June 15)")
    func lunarEclipsePrediction() {
        // k = -328.5 corresponds to Full Moon of 1973 June 15
        let eclipse = Eclipses.calculateLunar(k: -328.5)
        #expect(eclipse.hasEclipse)
        #expect(eclipse.isPenumbral)
        #expect(abs(eclipse.penumbralMagnitude - 0.47) < 0.05)
    }

    // MARK: - Calendars Tests
    @Test("Islamic/Hijri Calendar conversion (Meeus Example 9.a: 1421 AH, 1 Ramadan)")
    func islamicCalendarConversion() {
        let hijri = HijriDate(year: 1421, month: 9, day: 1)
        let julianComponents = hijri.toJulianCalendarDate()
        // In the Julian calendar, 1421 A.H. Ramadan 1 is 2000 November 15
        #expect(julianComponents.year == 2000)
        #expect(julianComponents.month == 11)
        #expect(julianComponents.day == 15)
        
        // In the Gregorian calendar, it corresponds to 2000 November 28
        let gregorianComponents = hijri.toGregorianCalendarDate()
        #expect(gregorianComponents.year == 2000)
        #expect(gregorianComponents.month == 11)
        #expect(gregorianComponents.day == 28)
    }

    @Test("Islamic Leap Year Check", arguments: [
        (1420, true),
        (1421, false),
        (1422, false),
        (1423, true),
        (1426, true)
    ])
    func islamicLeapYear(year: Int, expectedLeap: Bool) {
        let hijri = HijriDate(year: year, month: 1, day: 1)
        #expect(hijri.isLeapYear == expectedLeap)
    }

    @Test("Hebrew Calendar Pesach (Meeus Example 9.b: Jewish Year 5750 / Civil 1990)")
    func hebrewCalendarPesach() {
        let pesach = JewishDate.dateOfPesach(civilYear: 1990, inGregorianCalendar: true)
        // For civil year 1990 (5750 AM), Pesach is on 1990 April 10
        #expect(pesach.year == 1990)
        #expect(pesach.month == 4)
        #expect(pesach.day == 10)
    }

    @Test("Easter Sunday calculation", arguments: [
        (1991, 3, 31),
        (2024, 3, 31),
        (2025, 4, 20),
        (2026, 4, 5)
    ])
    func easterSunday(year: Int, expectedMonth: Int, expectedDay: Int) {
        let easter = Easter.calculate(year: year, inGregorianCalendar: true)
        #expect(easter.month == expectedMonth)
        #expect(easter.day == expectedDay)
    }

    // MARK: - Lunar Standstills
    @Test("Moon greatest Northern declination near 2024 (Major Standstill)")
    func lunarMajorStandstill() {
        let standstill = Moon.greatestDeclination(nearYear: 2024.5, northerly: true)
        #expect(standstill.isNortherly)
        #expect(standstill.declination.value > 27.5) // Major standstill reaches > 28°
    }

    // MARK: - Comets & Parabolic Orbits
    @Test("Parabolic orbit for Comet (Meeus Example 34.a)")
    func cometParabolicOrbit() {
        let elements = ParabolicOrbitElements(
            perihelionDistance: AstronomicalUnit(1.324558),
            inclination: Degree(22.4111),
            argumentOfPerihelion: Degree(130.6013),
            longitudeOfAscendingNode: Degree(12.4403),
            jdEquinox: JulianDay(2447891.5),
            timeOfPerihelion: JulianDay(2447810.0)
        )
        let details = ParabolicOrbit.calculate(julianDay: JulianDay(2447891.5), elements: elements)
        #expect(details.astrometricGeocentricDistance.value > 0)
        #expect(details.elongation.value > 0)
    }

    // MARK: - Air Mass & Observation Window
    @Test("Pickering Optical Air Mass values at zenith and horizon")
    func opticalAirMassValues() {
        let zenithAirMass = AtmosphericAirMass.pickeringAirMass(trueAltitude: Degree(90.0))
        #expect(abs(zenithAirMass - 1.0) < 1e-3)
        
        let midAirMass = AtmosphericAirMass.pickeringAirMass(trueAltitude: Degree(30.0))
        #expect(abs(midAirMass - 2.0) < 0.05)
        
        let horizonAirMass = AtmosphericAirMass.pickeringAirMass(trueAltitude: Degree(0.0))
        #expect(horizonAirMass > 30.0)
    }

    @Test("Observation window optimal conditions")
    func observationWindowCheck() {
        let coords = GeographicCoordinates(eastLongitude: Degree(2.35), latitude: Degree(48.85))
        let horiz = HorizontalCoordinates(azimuth: Degree(180), altitude: Degree(45), geographicCoordinates: coords, julianDay: JulianDay(2451545.0))
        
        let windowOptimal = horiz.observationWindow(sunAltitude: Degree(-20.0), minTargetAltitude: Degree(30.0))
        #expect(windowOptimal.isOptimal)
        
        let windowDaylight = horiz.observationWindow(sunAltitude: Degree(10.0), minTargetAltitude: Degree(30.0))
        #expect(!windowDaylight.isOptimal)
    }

    // MARK: - FormatStyles Tests
    @Test("Degree SexagesimalFormatStyle")
    func degreeSexagesimalFormatting() {
        let degPos = Degree(12.5891)
        #expect(degPos.formatted(.sexagesimal(includeSign: true, fractionDigits: 2)) == "+12° 35' 20.76\"")
        
        let degNeg = Degree(-15.4321)
        #expect(degNeg.formatted(.sexagesimal(includeSign: true, fractionDigits: 1)) == "-15° 25' 55.6\"")
    }

    @Test("Hour RightAscensionFormatStyle")
    func hourRightAscensionFormatting() {
        let ra = Hour(12.5891)
        #expect(ra.formatted(.rightAscension(fractionDigits: 2)) == "12h 35m 20.76s")
    }

    // MARK: - Foundation Measurement Interoperability
    @Test("Foundation Measurement<UnitAngle> conversions")
    func measurementAngleConversions() {
        let deg = Degree(180.0)
        let mAngle = deg.measurement
        #expect(mAngle.unit == .degrees)
        #expect(mAngle.value == 180.0)
        
        let degBack = Degree(Measurement(value: .pi, unit: .radians))
        #expect(abs(degBack.value - 180.0) < 1e-4)
    }

    @Test("Foundation Measurement<UnitLength> conversions")
    func measurementLengthConversions() {
        let au = AstronomicalUnit(1.0)
        let mLength = au.measurement
        #expect(mLength.unit == .astronomicalUnits)
        #expect(mLength.value == 1.0)
        
        let km = Kilometer(149597870.7)
        let mKm = km.measurement
        #expect(mKm.unit == .kilometers)
    }

    // MARK: - Codable Tests
    @Test("Codable round-trip for JulianDay, Degree, EquatorialCoordinates")
    func codableRoundTrip() throws {
        let jd = JulianDay(2451545.0)
        let data = try JSONEncoder().encode(jd)
        let decodedJD = try JSONDecoder().decode(JulianDay.self, from: data)
        #expect(decodedJD.value == jd.value)
        
        let eq = EquatorialCoordinates(rightAscension: Hour(12.5), declination: Degree(45.0))
        let eqData = try JSONEncoder().encode(eq)
        let decodedEq = try JSONDecoder().decode(EquatorialCoordinates.self, from: eqData)
        #expect(decodedEq.rightAscension.value == eq.rightAscension.value)
        #expect(decodedEq.declination.value == eq.declination.value)
    }
}
