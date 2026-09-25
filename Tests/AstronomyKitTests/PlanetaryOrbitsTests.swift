//
//  PlanetaryOrbitsTests.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 2017-09-20.
//  Copyright © 2017 onekiloparsec. All rights reserved.
//

import Testing
@testable import AstronomyKit

@Suite("PlanetaryOrbitsTests")
struct PlanetaryOrbitsTests {

    // See AA p.211, Example 31.a
    @Test("Mean Orbital Elements Of Mercury")
    func testMeanOrbitalElementsOfMercury() {
        let jd = JulianDay(2475460.5)
        let mercury = Mercury(julianDay: jd, highPrecision: false)

        // numeric types
        AssertEqual(mercury.semimajorAxis(), AstronomicalUnit(0.387098310))
        AssertEqual(mercury.inclination(.meanEquinoxOfTheDate(jd)), Degree(7.006171), accuracy: Degree(0.000001))
        AssertEqual(mercury.longitudeOfAscendingNode(.meanEquinoxOfTheDate(jd)), Degree(49.107650), accuracy: Degree(0.000001))
        AssertEqual(mercury.longitudeOfPerihelion(.meanEquinoxOfTheDate(jd)), Degree(78.475382), accuracy: Degree(0.000001))

        // non-numeric types
        #expect(abs(mercury.eccentricity() - 0.20564510) <= 0.00000001)
    }

    @Test("Joint PlanetaryOrbitalElements matches individual scalar getters")
    func testJointOrbitalElementsMercury() {
        let jd = 2475460.5
        let elements = CAAElementsPlanetaryOrbit.elements(for: .KPCAAPlanetStrictMercury, jd: jd)

        #expect(elements.semimajorAxis == 0.387098310)
        #expect(abs(elements.inclination - 7.006171) <= 0.000001)
        #expect(abs(elements.longitudeAscendingNode - 49.107650) <= 0.000001)
        #expect(abs(elements.longitudePerihelion - 78.475382) <= 0.000001)
        #expect(abs(elements.eccentricity - 0.20564510) <= 0.00000001)
    }

    @Test("Joint PlanetaryOrbitalElements are physically valid for all 8 major planets", arguments: [
        KPCAAPlanetStrict.KPCAAPlanetStrictMercury,
        .KPCAAPlanetStrictVenus,
        .KPCAAPlanetStrictEarth,
        .KPCAAPlanetStrictMars,
        .KPCAAPlanetStrictJupiter,
        .KPCAAPlanetStrictSaturn,
        .KPCAAPlanetStrictUranus,
        .KPCAAPlanetStrictNeptune
    ])
    func testJointOrbitalElementsAllPlanets(planet: KPCAAPlanetStrict) {
        let jd = 2451545.0 // J2000.0
        let dateElements = CAAElementsPlanetaryOrbit.elements(for: planet, jd: jd)
        let j2000Elements = CAAElementsPlanetaryOrbit.elementsJ2000(for: planet, jd: jd)

        #expect(dateElements.semimajorAxis > 0.0)
        #expect(dateElements.eccentricity >= 0.0 && dateElements.eccentricity < 1.0)
        #expect(dateElements.meanLongitude >= 0.0 && dateElements.meanLongitude <= 360.0)
        #expect(j2000Elements.meanLongitude >= 0.0 && j2000Elements.meanLongitude <= 360.0)
    }
}
