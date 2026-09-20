//
//  ModernAATests.swift
//  SwiftAA
//
//  Created for SwiftAA modernization with Swift-Testing.
//  MIT Licence. See LICENCE file.
//

import Testing
import Foundation
@testable import AstronomyKit

@Suite("Modern SwiftAA Astronomical Calculations")
struct ModernAATests {
    
    @Test("Julian Day calculation for standard J2000.0 epoch")
    func standardEpochJ2000() {
        let jd = JulianDay(year: 2000, month: 1, day: 1, hour: 12, minute: 0, second: 0)
        #expect(abs(jd.value - 2451545.0) < 1e-6)
    }

    @Test("Julian Day date round-trip conversion", arguments: [
        (1957, 10, 4, 19, 28, 34.0),
        (2000, 1, 1, 12, 0, 0.0),
        (2024, 4, 8, 18, 17, 0.0)
    ])
    func julianDayRoundTrip(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Double) {
        let jd = JulianDay(year: year, month: month, day: day, hour: hour, minute: minute, second: second)
        let date = jd.date
        #expect(date.year == year)
        #expect(date.month == month)
        #expect(date.day == day)
    }

    @Test("Earth Seasons Length for Year 2000")
    func earthSeasonLengths() {
        let earth = Earth(julianDay: JulianDay(year: 2000, month: 2, day: 1))
        let springLength = earth.lengthOfSeason(.spring, northernHemisphere: true)
        let summerLength = earth.lengthOfSeason(.summer, northernHemisphere: true)
        let autumnLength = earth.lengthOfSeason(.autumn, northernHemisphere: true)
        let winterLength = earth.lengthOfSeason(.winter, northernHemisphere: true)
        
        #expect(abs(springLength.value - 92.7586) < 0.01)
        #expect(abs(summerLength.value - 93.6526) < 0.01)
        #expect(abs(autumnLength.value - 89.8402) < 0.01)
        #expect(abs(winterLength.value - 88.9906) < 0.01)
    }

    @Test("Moon illuminated fraction range (0.0 to 1.0)")
    func moonIlluminatedFractionBounds() {
        let newMoonJD = JulianDay(year: 2024, month: 4, day: 8, hour: 18, minute: 21, second: 0)
        let moon = Moon(julianDay: newMoonJD)
        let fraction = moon.illuminatedFraction()
        
        #expect(fraction >= 0.0)
        #expect(fraction <= 1.0)
        #expect(fraction < 0.05) // Solar eclipse / new moon
    }

    @Test("Planetary type and name bindings", arguments: [
        (KPCAAPlanet.KPCAAPlanetMercury, "Mercury"),
        (KPCAAPlanet.KPCAAPlanetVenus, "Venus"),
        (KPCAAPlanet.KPCAAPlanetEarth, "Earth"),
        (KPCAAPlanet.KPCAAPlanetMars, "Mars"),
        (KPCAAPlanet.KPCAAPlanetJupiter, "Jupiter"),
        (KPCAAPlanet.KPCAAPlanetSaturn, "Saturn"),
        (KPCAAPlanet.KPCAAPlanetUranus, "Uranus"),
        (KPCAAPlanet.KPCAAPlanetNeptune, "Neptune"),
        (KPCAAPlanet.KPCAAPlanetPluto, "Pluto")
    ])
    func planetEnumStrings(planet: KPCAAPlanet, expectedName: String) {
        #expect(planet.description == expectedName)
        #expect(KPCAAPlanet.fromString(expectedName) == planet)
    }
}
